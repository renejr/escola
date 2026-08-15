from fastapi import FastAPI, HTTPException, Depends, Request, Header
from pydantic import BaseModel
import uvicorn
from dotenv import load_dotenv
import os
import jwt
from datetime import datetime, timedelta
import bcrypt
import asyncpg
import json

load_dotenv()

app = FastAPI(title="Auth Service - SaaS Escolar")

DATABASE_URL = os.getenv("DATABASE_URL")
JWT_SECRET = os.getenv("JWT_SECRET")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # 1 dia

class LoginRequest(BaseModel):
    email: str
    password: str

class ForgotPasswordRequest(BaseModel):
    email: str

async def get_db():
    conn = await asyncpg.connect(DATABASE_URL)
    try:
        yield conn
    finally:
        await conn.close()

@app.post("/auth/login")
async def login(req: LoginRequest, request: Request, conn: asyncpg.Connection = Depends(get_db)):
    # Buscar usuário no banco
    query = "SELECT id, nome, escola_id, papel, senha_hash FROM usuarios WHERE email = $1"
    user = await conn.fetchrow(query, req.email)
    
    if not user:
        raise HTTPException(status_code=401, detail="Email ou senha incorretos")
        
    # Verificar senha usando bcrypt puro
    is_password_correct = bcrypt.checkpw(
        req.password.encode('utf-8'), 
        user['senha_hash'].encode('utf-8')
    )
    
    if not is_password_correct:
        raise HTTPException(status_code=401, detail="Email ou senha incorretos")
    
    # Gerar payload do JWT conforme regra de negócio
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    payload = {
        "sub": str(user['id']),
        "escola_id": str(user['escola_id']) if user['escola_id'] else None,
        "role": user['papel'],
        "exp": expire
    }
    
    # Gerar o Token
    token = jwt.encode(payload, JWT_SECRET, algorithm=ALGORITHM)
    
    # Auditoria de Login
    ip = request.client.host if request.client else "unknown"
    detalhes = json.dumps({"email": req.email})
    try:
        escola_id_val = str(user['escola_id']) if user['escola_id'] else await conn.fetchval("SELECT id FROM escolas LIMIT 1")
        await conn.execute(
            "INSERT INTO audit_logs (escola_id, usuario_id, acao, detalhes, ip_address) VALUES ($1::uuid, $2::uuid, $3, $4::jsonb, $5)",
            str(escola_id_val), str(user['id']), 'LOGIN', detalhes, ip
        )
    except Exception as e:
        print(f"Erro ao registrar auditoria de login: {e}")
    
    return {
        "access_token": token, 
        "token_type": "bearer",
        "escola_id": user['escola_id'],
        "role": user['papel'],
        "nome": user['nome']
    }

@app.post("/auth/logout")
async def logout(request: Request, authorization: str = Header(None), conn: asyncpg.Connection = Depends(get_db)):
    if authorization and authorization.startswith("Bearer "):
        token = authorization.split(" ")[1]
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=[ALGORITHM])
            user_id = payload.get("sub")
            escola_id = payload.get("escola_id")
            if not escola_id:
                escola_id = await conn.fetchval("SELECT id FROM escolas LIMIT 1")
            
            ip = request.client.host if request.client else "unknown"
            
            await conn.execute(
                "INSERT INTO audit_logs (escola_id, usuario_id, acao, detalhes, ip_address) VALUES ($1::uuid, $2::uuid, $3, $4::jsonb, $5)",
                str(escola_id), user_id, 'LOGOUT', '{}', ip
            )
        except Exception as e:
            print(f"Erro ao processar logout ou auditoria: {e}")
            
    return {"message": "Logout processado com sucesso"}

@app.post("/auth/forgot-password")
async def forgot_password(req: ForgotPasswordRequest):
    print(f"Simulando envio de e-mail de recuperação para: {req.email}")
    return {"message": "Se o e-mail estiver cadastrado, você receberá um link de recuperação em instantes."}

@app.get("/auth/health")
def health_check():
    return {"status": "ok", "service": "Auth Service"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8081, reload=True)
