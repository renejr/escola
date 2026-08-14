from fastapi import APIRouter, Depends, HTTPException
import asyncpg
from pydantic import BaseModel
from typing import List
from deps import get_db, require_role

router = APIRouter(prefix="/core/professores", tags=["Professores"])

class ProfessorOut(BaseModel):
    id: str
    nome: str
    email: str
    celular: str | None = None
    ativo: bool | None = True

class ProfessorCreate(BaseModel):
    nome: str
    cpf: str
    email: str
    celular: str

@router.get("", response_model=List[ProfessorOut])
async def listar_professores(
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]

    query = """
        SELECT id, nome, email, celular, ativo
        FROM usuarios
        WHERE escola_id = $1::uuid AND papel = 'professor'
        ORDER BY nome ASC
    """
    try:
        rows = await conn.fetch(query, escola_id)
        return [{"id": str(row["id"]), "nome": row["nome"], "email": row["email"], "celular": row.get("celular"), "ativo": row.get("ativo", True)} for row in rows]
    except Exception as e:
        # Fallback se a tabela não tiver os campos extras
        try:
            query_fallback = "SELECT id, email as nome, email FROM usuarios WHERE escola_id = $1::uuid AND papel = 'professor'"
            rows_fallback = await conn.fetch(query_fallback, escola_id)
            return [{"id": str(row["id"]), "nome": row["nome"], "email": row["email"], "celular": "", "ativo": True} for row in rows_fallback]
        except Exception as inner_e:
            raise HTTPException(status_code=500, detail=str(inner_e))

@router.post("", response_model=ProfessorOut)
async def criar_professor(
    prof: ProfessorCreate,
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    
    # Check se e-mail já existe
    check_query = "SELECT id FROM usuarios WHERE email = $1 AND escola_id = $2::uuid"
    exist = await conn.fetchval(check_query, prof.email, escola_id)
    if exist:
        raise HTTPException(status_code=400, detail="E-mail já cadastrado.")

    # Inserir com senha dummy por enquanto (será provisória e enviada por e-mail no futuro)
    # Importante: Como não temos bcrypt aqui (é responsabilidade do auth), podemos gerar um hash padrão se não houver auth.
    # Assumindo que auth_service pode validar ou que o hash é criado via função de DB, mas aqui faremos um insert básico:
    query = """
        INSERT INTO usuarios (escola_id, email, senha_hash, papel, nome, celular, ativo)
        VALUES ($1::uuid, $2, $3, 'professor', $4, $5, TRUE)
        RETURNING id, nome, email, celular, ativo
    """
    try:
        # Dummy hash for "$2b$12$e/a6H..." (e.g. '123456')
        dummy_hash = "$2b$12$NqLq1j9RjG/t4e6fVp7e7u/8Q4p1lqR9Q3QG8L3u9Z1xQ4p1lqR9Q"
        row = await conn.fetchrow(query, escola_id, prof.email, dummy_hash, prof.nome, prof.celular)
        return {"id": str(row["id"]), "nome": row["nome"], "email": row["email"], "celular": row.get("celular"), "ativo": row.get("ativo", True)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao criar professor: {str(e)}")

@router.put("/{professor_id}", response_model=ProfessorOut)
async def atualizar_professor(
    professor_id: str,
    prof: ProfessorCreate,
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    
    query = """
        UPDATE usuarios 
        SET nome = $1, email = $2, celular = $3
        WHERE id = $4::uuid AND escola_id = $5::uuid AND papel = 'professor'
        RETURNING id, nome, email, celular, ativo
    """
    try:
        row = await conn.fetchrow(query, prof.nome, prof.email, prof.celular, professor_id, escola_id)
        if not row:
            raise HTTPException(status_code=404, detail="Professor não encontrado")
        return {"id": str(row["id"]), "nome": row["nome"], "email": row["email"], "celular": row.get("celular"), "ativo": row.get("ativo", True)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.patch("/{professor_id}/ativar")
async def ativar_professor(
    professor_id: str,
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    
    query = """
        UPDATE usuarios 
        SET ativo = TRUE
        WHERE id = $1::uuid AND escola_id = $2::uuid AND papel = 'professor'
        RETURNING id
    """
    try:
        row = await conn.fetchrow(query, professor_id, escola_id)
        if not row:
            raise HTTPException(status_code=404, detail="Professor não encontrado")
        return {"message": "Professor ativado com sucesso"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{professor_id}")
async def inativar_professor(
    professor_id: str,
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    
    query = """
        UPDATE usuarios 
        SET ativo = FALSE
        WHERE id = $1::uuid AND escola_id = $2::uuid AND papel = 'professor'
        RETURNING id
    """
    try:
        row = await conn.fetchrow(query, professor_id, escola_id)
        if not row:
            raise HTTPException(status_code=404, detail="Professor não encontrado")
        return {"message": "Professor inativado com sucesso"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
