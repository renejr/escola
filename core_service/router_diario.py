from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from datetime import date
from asyncpg.connection import Connection
from deps import get_db, get_tenant_context, require_role

router = APIRouter(prefix="/core/diario", tags=["Diário de Classe"])

# Models
class PeriodoLetivo(BaseModel):
    id: str
    nome: str
    data_inicio: date
    data_fim: date
    ativo: bool

class FrequenciaItem(BaseModel):
    aluno_id: str
    presente: bool

class FrequenciaBulk(BaseModel):
    turma_id: str
    materia_id: str
    data_aula: date
    frequencias: List[FrequenciaItem]

class NotaItem(BaseModel):
    aluno_id: str
    tipo_avaliacao: str
    valor_nota: float

class NotasBulk(BaseModel):
    turma_id: str
    materia_id: str
    periodo_letivo_id: str
    notas: List[NotaItem]

@router.get("/periodos", response_model=List[PeriodoLetivo])
async def list_periodos(
    user: dict = Depends(get_tenant_context),
    conn: Connection = Depends(get_db)
):
    escola_id = user.get("escola_id")
    records = await conn.fetch(
        """
        SELECT p.id::text, p.nome, p.data_inicio, p.data_fim, p.ativo 
        FROM periodos_letivos p
        JOIN anos_letivos a ON p.ano_letivo_id = a.id
        WHERE p.escola_id = $1::uuid AND a.ativo = true
        ORDER BY p.data_inicio
        """,
        escola_id
    )
    return [dict(r) for r in records]

@router.get("/frequencia")
async def get_frequencia(
    turma_id: str,
    materia_id: str,
    data_aula: date,
    user: dict = Depends(require_role(['admin', 'diretor', 'secretario', 'professor'])),
    conn: Connection = Depends(get_db)
):
    escola_id = user.get("escola_id")
    query = """
        SELECT aluno_id, presente 
        FROM diario_frequencia 
        WHERE escola_id = $1::uuid AND turma_id = $2::uuid AND materia_id = $3::uuid AND data_aula = $4
    """
    records = await conn.fetch(query, escola_id, turma_id, materia_id, data_aula)
    return [dict(r) for r in records]

@router.post("/frequencia/bulk")
async def save_frequencia_bulk(
    payload: FrequenciaBulk,
    user: dict = Depends(require_role(['admin', 'diretor', 'secretario', 'professor'])),
    conn: Connection = Depends(get_db)
):
    escola_id = user.get("escola_id")
    
    async with conn.transaction():
        for freq in payload.frequencias:
            query = """
                INSERT INTO diario_frequencia (escola_id, turma_id, materia_id, aluno_id, data_aula, presente)
                VALUES ($1::uuid, $2::uuid, $3::uuid, $4::uuid, $5, $6)
                ON CONFLICT (escola_id, turma_id, materia_id, aluno_id, data_aula)
                DO UPDATE SET presente = EXCLUDED.presente
            """
            await conn.execute(
                query,
                escola_id,
                payload.turma_id,
                payload.materia_id,
                freq.aluno_id,
                payload.data_aula,
                freq.presente
            )
            
    return {"message": "Frequência salva com sucesso"}

@router.get("/notas")
async def get_notas(
    turma_id: str,
    materia_id: str,
    periodo_letivo_id: str,
    user: dict = Depends(require_role(['admin', 'diretor', 'secretario', 'professor'])),
    conn: Connection = Depends(get_db)
):
    escola_id = user.get("escola_id")
    query = """
        SELECT aluno_id, tipo_avaliacao, valor_nota 
        FROM diario_notas 
        WHERE escola_id = $1::uuid AND turma_id = $2::uuid AND materia_id = $3::uuid AND periodo_letivo_id = $4::uuid
    """
    records = await conn.fetch(query, escola_id, turma_id, materia_id, periodo_letivo_id)
    return [dict(r) for r in records]

@router.post("/notas/bulk")
async def save_notas_bulk(
    payload: NotasBulk,
    user: dict = Depends(require_role(['admin', 'diretor', 'secretario', 'professor'])),
    conn: Connection = Depends(get_db)
):
    escola_id = user.get("escola_id")
    
    async with conn.transaction():
        for nota in payload.notas:
            query = """
                INSERT INTO diario_notas (escola_id, turma_id, materia_id, aluno_id, periodo_letivo_id, tipo_avaliacao, valor_nota)
                VALUES ($1::uuid, $2::uuid, $3::uuid, $4::uuid, $5::uuid, $6, $7)
                ON CONFLICT (escola_id, turma_id, materia_id, aluno_id, periodo_letivo_id, tipo_avaliacao)
                DO UPDATE SET valor_nota = EXCLUDED.valor_nota
            """
            await conn.execute(
                query,
                escola_id,
                payload.turma_id,
                payload.materia_id,
                nota.aluno_id,
                payload.periodo_letivo_id,
                nota.tipo_avaliacao,
                nota.valor_nota
            )
            
    return {"message": "Notas salvas com sucesso"}
