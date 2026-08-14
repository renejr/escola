from fastapi import APIRouter, Depends, HTTPException, Request
import asyncpg
from pydantic import BaseModel
from typing import List, Optional
from deps import get_db, require_role, registrar_auditoria

router = APIRouter(prefix="/core/materias", tags=["Materias"])

class MateriaCreate(BaseModel):
    nome: str
    area_conhecimento: Optional[str] = None

class MateriaOut(BaseModel):
    id: str
    escola_id: str
    nome: str
    area_conhecimento: Optional[str]
    ativo: bool

@router.post("", response_model=MateriaOut)
async def criar_materia(
    materia: MateriaCreate,
    request: Request,
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    usuario_id = tenant.get("sub")

    query = """
        INSERT INTO materias (escola_id, nome, area_conhecimento)
        VALUES ($1::uuid, $2, $3)
        RETURNING id, escola_id, nome, area_conhecimento, ativo
    """
    try:
        row = await conn.fetchrow(query, escola_id, materia.nome, materia.area_conhecimento)
        
        ip = request.client.host if request.client else "unknown"
        await registrar_auditoria(
            conn, 
            usuario_id=usuario_id, 
            acao='CREATE_MATERIA', 
            detalhes={"materia_id": str(row["id"]), "nome": materia.nome}, 
            ip_address=ip
        )
        
        return {**dict(row), "id": str(row["id"]), "escola_id": str(row["escola_id"])}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("", response_model=List[MateriaOut])
async def listar_materias(
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario', 'professor'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]

    query = "SELECT id, escola_id, nome, area_conhecimento, ativo FROM materias WHERE escola_id = $1::uuid AND ativo = TRUE ORDER BY nome ASC"
    rows = await conn.fetch(query, escola_id)
    
    return [{**dict(row), "id": str(row["id"]), "escola_id": str(row["escola_id"])} for row in rows]

@router.put("/{materia_id}", response_model=MateriaOut)
async def atualizar_materia(
    materia_id: str,
    materia: MateriaCreate,
    request: Request,
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    usuario_id = tenant.get("sub")

    query = """
        UPDATE materias 
        SET nome = $1, area_conhecimento = $2
        WHERE id = $3::uuid AND escola_id = $4::uuid
        RETURNING id, escola_id, nome, area_conhecimento, ativo
    """
    row = await conn.fetchrow(query, materia.nome, materia.area_conhecimento, materia_id, escola_id)
    
    if not row:
        raise HTTPException(status_code=404, detail="Matéria não encontrada")

    ip = request.client.host if request.client else "unknown"
    await registrar_auditoria(
        conn, 
        usuario_id=usuario_id, 
        acao='UPDATE_MATERIA', 
        detalhes={"materia_id": str(row["id"]), "nome": materia.nome}, 
        ip_address=ip
    )
    
    return {**dict(row), "id": str(row["id"]), "escola_id": str(row["escola_id"])}

@router.delete("/{materia_id}")
async def deletar_materia(
    materia_id: str,
    request: Request,
    tenant: dict = Depends(require_role(['admin', 'diretor'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    usuario_id = tenant.get("sub")

    query = "UPDATE materias SET ativo = FALSE WHERE id = $1::uuid AND escola_id = $2::uuid RETURNING id, nome"
    row = await conn.fetchrow(query, materia_id, escola_id)
    
    if not row:
        raise HTTPException(status_code=404, detail="Matéria não encontrada")

    ip = request.client.host if request.client else "unknown"
    await registrar_auditoria(
        conn, 
        usuario_id=usuario_id, 
        acao='DELETE_MATERIA', 
        detalhes={"materia_id": str(row["id"]), "nome": row["nome"]}, 
        ip_address=ip
    )
    
    return {"message": "Matéria desativada com sucesso"}
