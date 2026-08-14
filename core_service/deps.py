import os
import json
import jwt
from fastapi import HTTPException, Depends, Header
import asyncpg
from pgvector.asyncpg import register_vector
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
JWT_SECRET = os.getenv("JWT_SECRET")
ALGORITHM = "HS256"

async def get_db():
    conn = await asyncpg.connect(DATABASE_URL)
    await register_vector(conn)
    try:
        yield conn
    finally:
        await conn.close()

async def get_tenant_context(authorization: str = Header(...)):
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Formato de token inválido")
    
    token = authorization.split(" ")[1]
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[ALGORITHM])
        escola_id = payload.get("escola_id")
        if not escola_id:
            raise HTTPException(status_code=401, detail="escola_id não encontrado no token")
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expirado")
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Credenciais inválidas")

def require_role(allowed_roles: list):
    def role_checker(tenant: dict = Depends(get_tenant_context)):
        user_role = tenant.get("role")
        if user_role not in allowed_roles:
            raise HTTPException(status_code=403, detail="Acesso negado: permissão insuficiente")
        return tenant
    return role_checker

async def registrar_auditoria(conn: asyncpg.Connection, usuario_id: str, acao: str, detalhes: dict, ip_address: str):
    query = """
        INSERT INTO audit_logs (usuario_id, acao, detalhes, ip_address) 
        VALUES ($1, $2, $3::jsonb, $4)
    """
    try:
        await conn.execute(query, str(usuario_id), acao, json.dumps(detalhes), ip_address)
    except Exception as e:
        print(f"Erro ao registrar auditoria ({acao}): {e}")
