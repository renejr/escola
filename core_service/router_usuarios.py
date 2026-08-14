from fastapi import APIRouter, Depends, HTTPException
import asyncpg
from pydantic import BaseModel
from typing import List, Optional
from deps import get_db, require_role

router = APIRouter(prefix="/core/usuarios", tags=["Usuarios"])

class UsuarioOut(BaseModel):
    id: str
    nome: str
    email: str
    celular: Optional[str] = None
    papel: str
    ativo: Optional[bool] = True

class UsuarioCreate(BaseModel):
    nome: str
    email: str
    papel: str

class UsuarioUpdate(BaseModel):
    nome: str
    email: str
    papel: str

@router.get("", response_model=List[UsuarioOut])
async def listar_usuarios(
    tenant: dict = Depends(require_role(['admin', 'diretor'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]

    query = """
        SELECT id, nome, email, celular, papel, ativo
        FROM usuarios
        WHERE escola_id = $1::uuid
        ORDER BY nome ASC
    """
    try:
        rows = await conn.fetch(query, escola_id)
        return [{"id": str(row["id"]), "nome": row.get("nome", row["email"]), "email": row["email"], "celular": row.get("celular"), "papel": row["papel"], "ativo": row.get("ativo", True)} for row in rows]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("", response_model=UsuarioOut)
async def criar_usuario(
    user: UsuarioCreate,
    tenant: dict = Depends(require_role(['admin', 'diretor'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    
    check_query = "SELECT id FROM usuarios WHERE email = $1 AND escola_id = $2::uuid"
    exist = await conn.fetchval(check_query, user.email, escola_id)
    if exist:
        raise HTTPException(status_code=400, detail="E-mail já cadastrado.")

    query = """
        INSERT INTO usuarios (escola_id, email, senha_hash, papel, nome, ativo)
        VALUES ($1::uuid, $2, $3, $4, $5, TRUE)
        RETURNING id, nome, email, celular, papel, ativo
    """
    try:
        dummy_hash = "$2b$12$NqLq1j9RjG/t4e6fVp7e7u/8Q4p1lqR9Q3QG8L3u9Z1xQ4p1lqR9Q"
        row = await conn.fetchrow(query, escola_id, user.email, dummy_hash, user.papel, user.nome)
        return {"id": str(row["id"]), "nome": row.get("nome", row["email"]), "email": row["email"], "celular": row.get("celular"), "papel": row["papel"], "ativo": row.get("ativo", True)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao criar usuário: {str(e)}")

@router.put("/{usuario_id}", response_model=UsuarioOut)
async def atualizar_usuario(
    usuario_id: str,
    user: UsuarioUpdate,
    tenant: dict = Depends(require_role(['admin', 'diretor'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    
    query = """
        UPDATE usuarios 
        SET nome = $1, email = $2, papel = $3
        WHERE id = $4::uuid AND escola_id = $5::uuid
        RETURNING id, nome, email, celular, papel, ativo
    """
    try:
        row = await conn.fetchrow(query, user.nome, user.email, user.papel, usuario_id, escola_id)
        if not row:
            raise HTTPException(status_code=404, detail="Usuário não encontrado")
        return {"id": str(row["id"]), "nome": row.get("nome", row["email"]), "email": row["email"], "celular": row.get("celular"), "papel": row["papel"], "ativo": row.get("ativo", True)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.patch("/{usuario_id}/ativar")
async def toggle_status_usuario(
    usuario_id: str,
    tenant: dict = Depends(require_role(['admin', 'diretor'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    try:
        query_check = "SELECT ativo FROM usuarios WHERE id = $1::uuid AND escola_id = $2::uuid"
        status_atual = await conn.fetchval(query_check, usuario_id, escola_id)
        
        if status_atual is None:
            raise HTTPException(status_code=404, detail="Usuário não encontrado")
            
        novo_status = not status_atual
        
        query_update = """
            UPDATE usuarios SET ativo = $1 WHERE id = $2::uuid AND escola_id = $3::uuid
            RETURNING id, nome, email, celular, papel, ativo
        """
        row = await conn.fetchrow(query_update, novo_status, usuario_id, escola_id)
        return {"id": str(row["id"]), "nome": row.get("nome", row["email"]), "email": row["email"], "celular": row.get("celular"), "papel": row["papel"], "ativo": row.get("ativo", True)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
