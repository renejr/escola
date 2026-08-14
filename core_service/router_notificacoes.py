from fastapi import APIRouter, HTTPException, Depends, Request
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
import asyncpg

from deps import get_db, require_role, get_tenant_context

router = APIRouter(prefix="/core/notificacoes", tags=["Notificacoes"])

class NotificacaoOut(BaseModel):
    id: str
    escola_id: str
    titulo: str
    mensagem: str
    lido: bool
    turma_id: Optional[str] = None
    criado_em: datetime

@router.get("", response_model=List[NotificacaoOut])
async def listar_notificacoes(
    apenas_nao_lidas: bool = True,
    tenant: dict = Depends(get_tenant_context),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    
    query = """
        SELECT id, escola_id, titulo, mensagem, lido, turma_id, criado_em
        FROM notificacoes
        WHERE escola_id = $1::uuid
    """
    
    if apenas_nao_lidas:
        query += " AND lido = FALSE"
        
    query += " ORDER BY criado_em DESC"
    
    rows = await conn.fetch(query, escola_id)
    return [
        {
            **dict(row), 
            "id": str(row["id"]), 
            "escola_id": str(row["escola_id"]),
            "turma_id": str(row["turma_id"]) if row["turma_id"] else None
        } for row in rows
    ]

@router.put("/{notificacao_id}/ler")
async def marcar_como_lida(
    notificacao_id: str,
    tenant: dict = Depends(get_tenant_context),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    
    query = """
        UPDATE notificacoes
        SET lido = TRUE
        WHERE id = $1::uuid AND escola_id = $2::uuid
        RETURNING id
    """
    try:
        row = await conn.fetchrow(query, notificacao_id, escola_id)
        if not row:
            raise HTTPException(status_code=404, detail="Notificação não encontrada")
        return {"message": "Notificação marcada como lida"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))