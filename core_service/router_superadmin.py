from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from asyncpg.connection import Connection
from deps import require_superadmin, get_db

router = APIRouter(prefix="/core/superadmin", tags=["Super Admin"])

class EscolaCreate(BaseModel):
    razao_social: str
    cnpj: str
    nome_fantasia: str
    email_contato: Optional[str] = None
    telefone: Optional[str] = None

class EscolaUpdate(BaseModel):
    razao_social: str
    cnpj: str
    nome_fantasia: str
    email_contato: Optional[str] = None
    telefone: Optional[str] = None

@router.get("/kpis")
async def get_kpis(
    admin: dict = Depends(require_superadmin),
    conn: Connection = Depends(get_db)
):
    total_ativas = await conn.fetchval("SELECT count(*) FROM escolas WHERE ativo = 'true' OR ativo = '1'")
    total_inativas = await conn.fetchval("SELECT count(*) FROM escolas WHERE ativo = 'false' OR ativo = '0'")
    
    return {
        "ativas": total_ativas or 0,
        "inativas": total_inativas or 0
    }

@router.get("/escolas")
async def list_escolas(
    admin: dict = Depends(require_superadmin),
    conn: Connection = Depends(get_db)
):
    query = """
        SELECT id, razao_social, cnpj, nome_fantasia, email_contato, telefone, ativo, criado_em
        FROM escolas
        ORDER BY criado_em DESC
    """
    records = await conn.fetch(query)
    return [dict(r) for r in records]

@router.post("/escolas")
async def create_escola(
    escola: EscolaCreate,
    admin: dict = Depends(require_superadmin),
    conn: Connection = Depends(get_db)
):
    # Check if CNPJ exists
    exists = await conn.fetchval("SELECT id FROM escolas WHERE cnpj = $1", escola.cnpj)
    if exists:
        raise HTTPException(status_code=400, detail="CNPJ já cadastrado em outra escola.")
        
    query = """
        INSERT INTO escolas (razao_social, cnpj, nome_fantasia, email_contato, telefone, ativo, nome)
        VALUES ($1, $2, $3, $4, $5, 'true', $6)
        RETURNING id
    """
    new_id = await conn.fetchval(
        query,
        escola.razao_social,
        escola.cnpj,
        escola.nome_fantasia,
        escola.email_contato,
        escola.telefone,
        escola.nome_fantasia
    )
    return {"message": "Escola provisionada com sucesso", "id": new_id}

@router.put("/escolas/{escola_id}")
async def update_escola(
    escola_id: str,
    escola: EscolaUpdate,
    admin: dict = Depends(require_superadmin),
    conn: Connection = Depends(get_db)
):
    query = """
        UPDATE escolas
        SET razao_social = $1,
            cnpj = $2,
            nome_fantasia = $3,
            email_contato = $4,
            telefone = $5
        WHERE id = $6::uuid
        RETURNING id
    """
    updated = await conn.fetchval(
        query,
        escola.razao_social,
        escola.cnpj,
        escola.nome_fantasia,
        escola.email_contato,
        escola.telefone,
        escola_id
    )
    if not updated:
        raise HTTPException(status_code=404, detail="Escola não encontrada")
    
    return {"message": "Escola atualizada com sucesso"}

@router.patch("/escolas/{escola_id}/toggle-status")
async def toggle_status_escola(
    escola_id: str,
    admin: dict = Depends(require_superadmin),
    conn: Connection = Depends(get_db)
):
    current = await conn.fetchval("SELECT ativo FROM escolas WHERE id = $1::uuid", escola_id)
    if current is None:
        raise HTTPException(status_code=404, detail="Escola não encontrada")
        
    is_active = (current == 'true' or current == '1' or current == True)
    new_status = not is_active
    new_status_str = 'true' if new_status else 'false'
    await conn.execute("UPDATE escolas SET ativo = $1 WHERE id = $2::uuid", new_status_str, escola_id)
    
    return {"message": f"Escola {'ativada' if new_status else 'inativada'} com sucesso", "ativo": new_status_str}
