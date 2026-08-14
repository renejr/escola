from fastapi import APIRouter, Depends, HTTPException, Request
import asyncpg
from pydantic import BaseModel
from typing import List, Optional
from deps import get_db, require_role, registrar_auditoria

router = APIRouter(prefix="/core/grade", tags=["Grade Curricular"])

class GradeCreate(BaseModel):
    materia_id: str
    turma_id: str
    professor_id: str
    carga_horaria: int

class GradeOut(BaseModel):
    id: str
    materia_id: str
    materia_nome: str
    turma_id: str
    professor_id: str
    carga_horaria: int
    ativo: bool

@router.post("", response_model=GradeOut)
async def adicionar_grade(
    grade: GradeCreate,
    request: Request,
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    usuario_id = tenant.get("sub")

    query = """
        INSERT INTO grade_curricular (escola_id, turma_id, materia_id, professor_id, carga_horaria)
        VALUES ($1::uuid, $2::uuid, $3::uuid, $4::uuid, $5)
        RETURNING id, materia_id, turma_id, professor_id, carga_horaria, ativo
    """
    try:
        row = await conn.fetchrow(query, escola_id, grade.turma_id, grade.materia_id, grade.professor_id, grade.carga_horaria)
        
        # Buscar nome da matéria para retorno
        materia_nome = await conn.fetchval("SELECT nome FROM materias WHERE id = $1::uuid", grade.materia_id)
        
        ip = request.client.host if request.client else "unknown"
        await registrar_auditoria(
            conn, 
            usuario_id=usuario_id, 
            acao='CREATE_GRADE', 
            detalhes={"grade_id": str(row["id"]), "turma_id": grade.turma_id, "materia_id": grade.materia_id}, 
            ip_address=ip
        )
        
        return {
            "id": str(row["id"]),
            "materia_id": str(row["materia_id"]),
            "materia_nome": materia_nome,
            "turma_id": str(row["turma_id"]),
            "professor_id": str(row["professor_id"]),
            "carga_horaria": row["carga_horaria"],
            "ativo": row["ativo"]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{turma_id}", response_model=List[GradeOut])
async def listar_grade_turma(
    turma_id: str,
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario', 'professor'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]

    query = """
        SELECT g.id, g.materia_id, m.nome as materia_nome, g.turma_id, g.professor_id, g.carga_horaria, g.ativo 
        FROM grade_curricular g
        JOIN materias m ON g.materia_id = m.id
        WHERE g.escola_id = $1::uuid AND g.turma_id = $2::uuid AND g.ativo = TRUE
        ORDER BY m.nome ASC
    """
    rows = await conn.fetch(query, escola_id, turma_id)
    
    return [{
        "id": str(row["id"]),
        "materia_id": str(row["materia_id"]),
        "materia_nome": row["materia_nome"],
        "turma_id": str(row["turma_id"]),
        "professor_id": str(row["professor_id"]),
        "carga_horaria": row["carga_horaria"],
        "ativo": row["ativo"]
    } for row in rows]

@router.delete("/{grade_id}")
async def remover_grade(
    grade_id: str,
    request: Request,
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    usuario_id = tenant.get("sub")

    query = "DELETE FROM grade_curricular WHERE id = $1::uuid AND escola_id = $2::uuid RETURNING id, turma_id, materia_id"
    row = await conn.fetchrow(query, grade_id, escola_id)
    
    if not row:
        raise HTTPException(status_code=404, detail="Item da grade não encontrado")

    ip = request.client.host if request.client else "unknown"
    await registrar_auditoria(
        conn, 
        usuario_id=usuario_id, 
        acao='DELETE_GRADE', 
        detalhes={"grade_id": str(row["id"]), "turma_id": str(row["turma_id"]), "materia_id": str(row["materia_id"])}, 
        ip_address=ip
    )
    
    return {"message": "Item removido da grade com sucesso"}