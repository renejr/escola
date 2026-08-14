from fastapi import APIRouter, HTTPException, Depends, Request
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
import asyncpg

from deps import get_db, require_role, get_tenant_context, registrar_auditoria

router = APIRouter(prefix="/core/agenda", tags=["Agenda"])

class EventoAgendaCreate(BaseModel):
    titulo: str
    descricao: Optional[str] = None
    data_inicio: datetime
    data_fim: datetime
    tipo: str
    turma_id: Optional[str] = None
    gerar_notificacao: Optional[bool] = False

class EventoAgendaOut(BaseModel):
    id: str
    escola_id: str
    titulo: str
    descricao: Optional[str] = None
    data_inicio: datetime
    data_fim: datetime
    tipo: str
    turma_id: Optional[str] = None

@router.post("", response_model=EventoAgendaOut)
async def criar_evento(
    evento: EventoAgendaCreate, 
    request: Request,
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    usuario_id = tenant.get("sub")
    
    query = """
        INSERT INTO eventos_agenda (escola_id, titulo, descricao, data_inicio, data_fim, tipo, turma_id) 
        VALUES ($1::uuid, $2, $3, $4, $5, $6, $7::uuid) 
        RETURNING id, escola_id, titulo, descricao, data_inicio, data_fim, tipo, turma_id
    """
    
    turma_uuid = evento.turma_id if evento.turma_id else None
    
    try:
        row = await conn.fetchrow(
            query, 
            escola_id, 
            evento.titulo, 
            evento.descricao, 
            evento.data_inicio, 
            evento.data_fim, 
            evento.tipo, 
            turma_uuid
        )
        
        ip = request.client.host if request.client else "unknown"
        await registrar_auditoria(
            conn, 
            usuario_id=usuario_id, 
            acao='CREATE_EVENTO', 
            detalhes={"evento_id": str(row["id"]), "titulo": evento.titulo}, 
            ip_address=ip
        )
        
        if getattr(evento, 'gerar_notificacao', False):
            msg = f"Data: {evento.data_inicio.strftime('%d/%m/%Y %H:%M')}"
            tit = f"Novo Evento: {evento.titulo}"
            notif_query = """
                INSERT INTO notificacoes (escola_id, titulo, mensagem, turma_id)
                VALUES ($1::uuid, $2, $3, $4::uuid)
            """
            await conn.execute(notif_query, escola_id, tit, msg, turma_uuid)
        
        return {
            **dict(row), 
            "id": str(row["id"]), 
            "escola_id": str(row["escola_id"]),
            "turma_id": str(row["turma_id"]) if row["turma_id"] else None
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("", response_model=List[EventoAgendaOut])
async def listar_eventos(
    tenant: dict = Depends(get_tenant_context),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    
    query = """
        SELECT id, escola_id, titulo, descricao, data_inicio, data_fim, tipo, turma_id
        FROM eventos_agenda
        WHERE escola_id = $1::uuid
        ORDER BY data_inicio ASC
    """
    rows = await conn.fetch(query, escola_id)
    return [
        {
            **dict(row), 
            "id": str(row["id"]), 
            "escola_id": str(row["escola_id"]),
            "turma_id": str(row["turma_id"]) if row["turma_id"] else None
        } for row in rows
    ]

@router.put("/{evento_id}", response_model=EventoAgendaOut)
async def atualizar_evento(
    evento_id: str,
    evento: EventoAgendaCreate,
    request: Request,
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    usuario_id = tenant.get("sub")
    turma_uuid = evento.turma_id if evento.turma_id else None
    
    query = """
        UPDATE eventos_agenda 
        SET titulo = $1, descricao = $2, data_inicio = $3, data_fim = $4, tipo = $5, turma_id = $6::uuid
        WHERE id = $7::uuid AND escola_id = $8::uuid
        RETURNING id, escola_id, titulo, descricao, data_inicio, data_fim, tipo, turma_id
    """
    try:
        row = await conn.fetchrow(
            query, 
            evento.titulo, 
            evento.descricao, 
            evento.data_inicio, 
            evento.data_fim, 
            evento.tipo, 
            turma_uuid,
            evento_id, 
            escola_id
        )
        
        if not row:
            raise HTTPException(status_code=404, detail="Evento não encontrado")
            
        ip = request.client.host if request.client else "unknown"
        await registrar_auditoria(
            conn, 
            usuario_id=usuario_id, 
            acao='UPDATE_EVENTO', 
            detalhes={"evento_id": str(row["id"]), "titulo": evento.titulo}, 
            ip_address=ip
        )
        
        return {
            **dict(row), 
            "id": str(row["id"]), 
            "escola_id": str(row["escola_id"]),
            "turma_id": str(row["turma_id"]) if row["turma_id"] else None
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{evento_id}")
async def deletar_evento(
    evento_id: str,
    request: Request,
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    usuario_id = tenant.get("sub")
    
    query = "DELETE FROM eventos_agenda WHERE id = $1::uuid AND escola_id = $2::uuid RETURNING id"
    try:
        row = await conn.fetchrow(query, evento_id, escola_id)
        if not row:
            raise HTTPException(status_code=404, detail="Evento não encontrado")
            
        ip = request.client.host if request.client else "unknown"
        await registrar_auditoria(
            conn, 
            usuario_id=usuario_id, 
            acao='DELETE_EVENTO', 
            detalhes={"evento_id": evento_id}, 
            ip_address=ip
        )
        return {"message": "Evento deletado com sucesso"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))