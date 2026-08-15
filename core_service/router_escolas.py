from fastapi import APIRouter, Depends, HTTPException
from deps import require_role, get_db
from pydantic import BaseModel
from typing import Optional
from asyncpg.connection import Connection

router = APIRouter(prefix="/core/escola", tags=["Escolas"])

class EscolaUpdate(BaseModel):
    razao_social: str
    cnpj: str
    nome_fantasia: str
    logo_url: Optional[str] = None
    cor_primaria: Optional[str] = None
    telefone: Optional[str] = None
    email_contato: Optional[str] = None

@router.get("/minha-instituicao")
async def get_minha_escola(
    tenant: dict = Depends(require_role(['admin', 'diretor'])),
    conn: Connection = Depends(get_db)
):
    escola_id = tenant.get('escola_id')
    if not escola_id:
        raise HTTPException(status_code=400, detail="Usuário não vinculado a uma escola")
    
    query = """
        SELECT id, razao_social, cnpj, nome_fantasia, logo_url, cor_primaria, telefone, email_contato, ativo
        FROM escolas
        WHERE id = $1::uuid
    """
    record = await conn.fetchrow(query, escola_id)
    if not record:
        raise HTTPException(status_code=404, detail="Escola não encontrada")
    
    return dict(record)

@router.put("/minha-instituicao")
async def update_minha_escola(
    escola: EscolaUpdate,
    tenant: dict = Depends(require_role(['admin', 'diretor'])),
    conn: Connection = Depends(get_db)
):
    escola_id = tenant.get('escola_id')
    if not escola_id:
        raise HTTPException(status_code=400, detail="Usuário não vinculado a uma escola")
    
    query = """
        UPDATE escolas
        SET razao_social = $1,
            cnpj = $2,
            nome_fantasia = $3,
            logo_url = $4,
            cor_primaria = $5,
            telefone = $6,
            email_contato = $7
        WHERE id = $8::uuid
        RETURNING id
    """
    updated_id = await conn.fetchval(
        query,
        escola.razao_social,
        escola.cnpj,
        escola.nome_fantasia,
        escola.logo_url,
        escola.cor_primaria,
        escola.telefone,
        escola.email_contato,
        escola_id
    )
    
    if not updated_id:
        raise HTTPException(status_code=404, detail="Escola não encontrada ou erro ao atualizar")
    
    return {"message": "Dados da instituição atualizados com sucesso", "id": updated_id}
