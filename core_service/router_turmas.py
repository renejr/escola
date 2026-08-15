from fastapi import APIRouter, HTTPException, Depends, Request
from pydantic import BaseModel
from typing import List, Optional
import asyncpg

from deps import get_db, require_role, get_tenant_context, registrar_auditoria

router = APIRouter(prefix="/core/turmas", tags=["Turmas"])

class TurmaCreate(BaseModel):
    nome: str
    turno: Optional[str] = None
    ano_letivo: Optional[str] = None
    sala: Optional[str] = None

class TurmaOut(BaseModel):
    id: str
    nome: str
    escola_id: str
    turno: Optional[str] = None
    ano_letivo: Optional[str] = None
    sala: Optional[str] = None
    ativo: Optional[bool] = True
    total_alunos: Optional[int] = 0

class TurmaAlunoOut(BaseModel):
    id: str
    nome: str
    matricula_ra: Optional[str] = None
    ativo: Optional[bool] = True

class TurmaGradeOut(BaseModel):
    id: str
    materia_nome: str
    professor_nome: Optional[str] = None
    carga_horaria: int

@router.post("", response_model=TurmaOut)
async def criar_turma(
    turma: TurmaCreate, 
    request: Request,
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    usuario_id = tenant.get("sub")
    
    query = """
        INSERT INTO turmas (nome, escola_id, turno, ano_letivo, sala, ativo) 
        VALUES ($1, $2::uuid, $3, $4, $5, TRUE) 
        RETURNING id, nome, escola_id, turno, ano_letivo, sala, ativo
    """
    try:
        row = await conn.fetchrow(query, turma.nome, escola_id, turma.turno, turma.ano_letivo, turma.sala)
        
        ip = request.client.host if request.client else "unknown"
        await registrar_auditoria(
            conn, 
            usuario_id=usuario_id, 
            acao='CREATE_TURMA', 
            detalhes={"turma_id": str(row["id"]), "nome": turma.nome}, 
            ip_address=ip
        )
        
        return {**dict(row), "id": str(row["id"]), "escola_id": str(row["escola_id"]), "total_alunos": 0}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("", response_model=List[TurmaOut])
async def listar_turmas(
    tenant: dict = Depends(get_tenant_context),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant.get("escola_id")
    
    query = """
        SELECT t.id, t.nome, t.escola_id, t.turno, t.ano_letivo, t.sala, t.ativo,
               (SELECT COUNT(*) FROM alunos a WHERE a.turma_id = t.id AND a.ativo = TRUE) as total_alunos
        FROM turmas t
        WHERE t.escola_id = $1::uuid
        ORDER BY t.nome ASC
    """
    rows = await conn.fetch(query, escola_id)
    return [
        {
            **dict(row), 
            "id": str(row["id"]), 
            "escola_id": str(row["escola_id"])
        } for row in rows
    ]

@router.put("/{turma_id}", response_model=TurmaOut)
async def atualizar_turma(
    turma_id: str,
    turma: TurmaCreate,
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    
    query = """
        UPDATE turmas 
        SET nome = $1, turno = $2, ano_letivo = $3, sala = $4
        WHERE id = $5::uuid AND escola_id = $6::uuid
        RETURNING id, nome, escola_id, turno, ano_letivo, sala, ativo
    """
    try:
        row = await conn.fetchrow(query, turma.nome, turma.turno, turma.ano_letivo, turma.sala, turma_id, escola_id)
        if not row:
            raise HTTPException(status_code=404, detail="Turma não encontrada")
        
        # Get count
        count_query = "SELECT COUNT(*) FROM alunos WHERE turma_id = $1::uuid AND ativo = TRUE"
        count = await conn.fetchval(count_query, turma_id)
        
        return {**dict(row), "id": str(row["id"]), "escola_id": str(row["escola_id"]), "total_alunos": count}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.patch("/{turma_id}/status")
async def toggle_status_turma(
    turma_id: str,
    ativo: bool,
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    
    query = "UPDATE turmas SET ativo = $1 WHERE id = $2::uuid AND escola_id = $3::uuid RETURNING id"
    try:
        row = await conn.fetchrow(query, ativo, turma_id, escola_id)
        if not row:
            raise HTTPException(status_code=404, detail="Turma não encontrada")
        return {"message": f"Turma {'ativada' if ativo else 'inativada'} com sucesso"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{turma_id}/alunos", response_model=List[TurmaAlunoOut])
async def listar_alunos_turma(
    turma_id: str,
    tenant: dict = Depends(get_tenant_context),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    
    query = """
        SELECT id, nome, matricula_ra, ativo
        FROM alunos
        WHERE turma_id = $1::uuid AND escola_id = $2::uuid
        ORDER BY nome ASC
    """
    rows = await conn.fetch(query, turma_id, escola_id)
    return [{"id": str(row["id"]), "nome": row["nome"], "matricula_ra": row.get("matricula_ra"), "ativo": row.get("ativo", True)} for row in rows]

@router.get("/{turma_id}/grade", response_model=List[TurmaGradeOut])
async def listar_grade_turma(
    turma_id: str,
    tenant: dict = Depends(get_tenant_context),
    conn: asyncpg.Connection = Depends(get_db)
):
    # Validar a escola_id pode ser feita com um join se necessario, mas como grade tem turma_id, 
    # e turma_id é da escola (garantido pela criacao), podemos simplificar ou fazer join.
    escola_id = tenant["escola_id"]
    
    query = """
        SELECT g.id, m.nome as materia_nome, u.nome as professor_nome, g.carga_horaria
        FROM grade_curricular g
        JOIN materias m ON g.materia_id = m.id
        LEFT JOIN usuarios u ON g.professor_id = u.id
        JOIN turmas t ON g.turma_id = t.id
        WHERE g.turma_id = $1::uuid AND t.escola_id = $2::uuid AND g.ativo = TRUE
    """
    rows = await conn.fetch(query, turma_id, escola_id)
    return [{"id": str(row["id"]), "materia_nome": row["materia_nome"], "professor_nome": row.get("professor_nome"), "carga_horaria": row["carga_horaria"]} for row in rows]