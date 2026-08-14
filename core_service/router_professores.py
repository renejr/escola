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

@router.get("", response_model=List[ProfessorOut])
async def listar_professores(
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]

    query = """
        SELECT id, nome, email 
        FROM usuarios 
        WHERE escola_id = $1::uuid AND papel = 'professor' AND ativo = TRUE
        ORDER BY nome ASC
    """
    try:
        rows = await conn.fetch(query, escola_id)
        return [{"id": str(row["id"]), "nome": row["nome"], "email": row["email"]} for row in rows]
    except Exception as e:
        # Tabela usuarios pode não ter 'nome' ou 'ativo', dependendo do schema atual.
        # Vamos tratar caso falhe e tentar apenas com id, email
        try:
            query_fallback = "SELECT id, email as nome, email FROM usuarios WHERE escola_id = $1::uuid AND papel = 'professor'"
            rows_fallback = await conn.fetch(query_fallback, escola_id)
            return [{"id": str(row["id"]), "nome": row["nome"], "email": row["email"]} for row in rows_fallback]
        except Exception as inner_e:
            raise HTTPException(status_code=500, detail=str(inner_e))
