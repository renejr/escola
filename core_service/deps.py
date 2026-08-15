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

async def require_superadmin(authorization: str = Header(...)):
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Formato de token inválido")
    
    token = authorization.split(" ")[1]
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[ALGORITHM])
        user_role = payload.get("role")
        if user_role != "superadmin":
            raise HTTPException(status_code=403, detail="Acesso negado: Requer privilégios de Super Admin")
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
    escola_id = None
    if usuario_id:
        try:
            escola_id = await conn.fetchval("SELECT escola_id FROM usuarios WHERE id = $1::uuid", str(usuario_id))
        except Exception:
            pass
            
    if not escola_id:
        try:
            escola_id = await conn.fetchval("SELECT id FROM escolas LIMIT 1")
        except Exception:
            pass

    query = """
        INSERT INTO audit_logs (escola_id, usuario_id, acao, detalhes, ip_address) 
        VALUES ($1::uuid, $2::uuid, $3, $4::jsonb, $5)
    """
    try:
        await conn.execute(query, escola_id, str(usuario_id) if usuario_id else None, acao, json.dumps(detalhes), ip_address)
    except Exception as e:
        print(f"Erro ao registrar auditoria ({acao}): {e}")
