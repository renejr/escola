from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from datetime import date
from asyncpg.connection import Connection
from deps import get_db, get_tenant_context, require_role

router = APIRouter(prefix="/core/periodos", tags=["Anos e Períodos Letivos"])

# Models Anos Letivos
class AnoLetivoCreate(BaseModel):
    ano: str

class AnoLetivoResponse(BaseModel):
    id: str
    ano: str
    ativo: bool

# Models Períodos Letivos
class PeriodoLetivoCreate(BaseModel):
    ano_letivo_id: str
    nome: str
    data_inicio: date
    data_fim: date

class PeriodoLetivoResponse(BaseModel):
    id: str
    ano_letivo_id: str
    nome: str
    data_inicio: date
    data_fim: date
    ativo: bool

# --- ANOS LETIVOS ---

@router.get("/anos", response_model=List[AnoLetivoResponse])
async def list_anos_letivos(
    user: dict = Depends(get_tenant_context),
    conn: Connection = Depends(get_db)
):
    escola_id = user.get("escola_id")
    records = await conn.fetch(
        "SELECT id::text, ano, ativo FROM anos_letivos WHERE escola_id = $1::uuid ORDER BY ano DESC",
        escola_id
    )
    return [dict(r) for r in records]

@router.post("/anos", response_model=AnoLetivoResponse)
async def create_ano_letivo(
    payload: AnoLetivoCreate,
    user: dict = Depends(require_role(['admin', 'diretor'])),
    conn: Connection = Depends(get_db)
):
    escola_id = user.get("escola_id")
    
    # Check if year already exists for this school
    exists = await conn.fetchval(
        "SELECT id FROM anos_letivos WHERE escola_id = $1::uuid AND ano = $2",
        escola_id, payload.ano
    )
    if exists:
        raise HTTPException(status_code=400, detail="Ano letivo já cadastrado.")

    # Se for o primeiro ano, já nasce ativo
    count = await conn.fetchval("SELECT count(*) FROM anos_letivos WHERE escola_id = $1::uuid", escola_id)
    is_ativo = count == 0

    query = """
        INSERT INTO anos_letivos (escola_id, ano, ativo)
        VALUES ($1::uuid, $2, $3)
        RETURNING id::text, ano, ativo
    """
    record = await conn.fetchrow(query, escola_id, payload.ano, is_ativo)
    return dict(record)

@router.patch("/anos/{ano_id}/ativar")
async def ativar_ano_letivo(
    ano_id: str,
    user: dict = Depends(require_role(['admin', 'diretor'])),
    conn: Connection = Depends(get_db)
):
    escola_id = user.get("escola_id")
    
    async with conn.transaction():
        # Desativa todos os outros
        await conn.execute(
            "UPDATE anos_letivos SET ativo = false WHERE escola_id = $1::uuid",
            escola_id
        )
        # Ativa o selecionado
        updated = await conn.execute(
            "UPDATE anos_letivos SET ativo = true WHERE id = $1::uuid AND escola_id = $2::uuid",
            ano_id, escola_id
        )
        if updated == "UPDATE 0":
            raise HTTPException(status_code=404, detail="Ano letivo não encontrado.")
            
    return {"message": "Ano letivo ativado com sucesso."}

# --- PERÍODOS LETIVOS ---

@router.get("/anos/{ano_id}/periodos", response_model=List[PeriodoLetivoResponse])
async def list_periodos_letivos(
    ano_id: str,
    user: dict = Depends(get_tenant_context),
    conn: Connection = Depends(get_db)
):
    escola_id = user.get("escola_id")
    records = await conn.fetch(
        """
        SELECT id::text, ano_letivo_id::text, nome, data_inicio, data_fim, ativo 
        FROM periodos_letivos 
        WHERE escola_id = $1::uuid AND ano_letivo_id = $2::uuid 
        ORDER BY data_inicio
        """,
        escola_id, ano_id
    )
    return [dict(r) for r in records]

@router.post("/periodos", response_model=PeriodoLetivoResponse)
async def create_periodo_letivo(
    payload: PeriodoLetivoCreate,
    user: dict = Depends(require_role(['admin', 'diretor'])),
    conn: Connection = Depends(get_db)
):
    escola_id = user.get("escola_id")
    
    query = """
        INSERT INTO periodos_letivos (escola_id, ano_letivo_id, nome, data_inicio, data_fim, ativo)
        VALUES ($1::uuid, $2::uuid, $3, $4, $5, true)
        RETURNING id::text, ano_letivo_id::text, nome, data_inicio, data_fim, ativo
    """
    record = await conn.fetchrow(
        query, 
        escola_id, 
        payload.ano_letivo_id, 
        payload.nome, 
        payload.data_inicio, 
        payload.data_fim
    )
    return dict(record)
