from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel
import asyncpg
from typing import Optional, List
import json

from deps import get_db, require_role, registrar_auditoria

router = APIRouter(prefix="/core/responsaveis", tags=["Responsaveis"])

class ResponsavelCreate(BaseModel):
    nome: str
    cpf: str
    email: str
    celular: str
    emergencia_nome: Optional[str] = None
    emergencia_telefone: Optional[str] = None
    cep: Optional[str] = None
    logradouro: Optional[str] = None
    numero: Optional[str] = None
    complemento: Optional[str] = None
    bairro: Optional[str] = None
    cidade: Optional[str] = None
    estado: Optional[str] = None
    foto_url: Optional[str] = None
    comprovante_url: Optional[str] = None

class ResponsavelUpdate(BaseModel):
    nome: Optional[str] = None
    cpf: Optional[str] = None
    email: Optional[str] = None
    celular: Optional[str] = None
    emergencia_nome: Optional[str] = None
    emergencia_telefone: Optional[str] = None
    cep: Optional[str] = None
    logradouro: Optional[str] = None
    numero: Optional[str] = None
    complemento: Optional[str] = None
    bairro: Optional[str] = None
    cidade: Optional[str] = None
    estado: Optional[str] = None
    foto_url: Optional[str] = None
    comprovante_url: Optional[str] = None
    ativo: Optional[bool] = None

@router.post("")
async def criar_responsavel(
    responsavel: ResponsavelCreate,
    request: Request,
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    usuario_id = tenant.get("sub")
    
    query = """
        INSERT INTO responsaveis (
            escola_id, nome, cpf, email, celular, emergencia_nome, emergencia_telefone,
            cep, logradouro, numero, complemento, bairro, cidade, estado, foto_url, comprovante_url
        ) VALUES (
            $1::uuid, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16
        ) RETURNING id
    """
    
    try:
        responsavel_id = await conn.fetchval(
            query, escola_id, responsavel.nome, responsavel.cpf, responsavel.email, responsavel.celular,
            responsavel.emergencia_nome, responsavel.emergencia_telefone, responsavel.cep, responsavel.logradouro,
            responsavel.numero, responsavel.complemento, responsavel.bairro, responsavel.cidade, responsavel.estado,
            responsavel.foto_url, responsavel.comprovante_url
        )
        
        ip = request.client.host if request.client else "unknown"
        await registrar_auditoria(
            conn, usuario_id=usuario_id, acao='CREATE_RESPONSAVEL', 
            detalhes={"id": str(responsavel_id), "nome": responsavel.nome}, ip_address=ip
        )
        
        return {"id": str(responsavel_id), "message": "Responsável criado com sucesso"}
    except asyncpg.UniqueViolationError:
        raise HTTPException(status_code=400, detail="CPF ou E-mail já cadastrado nesta escola.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("")
async def listar_responsaveis(
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario', 'professor'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    query = "SELECT * FROM responsaveis WHERE escola_id = $1::uuid ORDER BY nome"
    
    rows = await conn.fetch(query, escola_id)
    return [dict(row) for row in rows]

@router.put("/{responsavel_id}")
async def atualizar_responsavel(
    responsavel_id: str,
    dados: ResponsavelUpdate,
    request: Request,
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    usuario_id = tenant.get("sub")
    
    # Montar query dinâmica
    update_data = dados.dict(exclude_unset=True)
    if not update_data:
        raise HTTPException(status_code=400, detail="Nenhum dado fornecido para atualização")
        
    set_clauses = []
    values = [escola_id, responsavel_id]
    
    for i, (key, value) in enumerate(update_data.items(), start=3):
        set_clauses.append(f"{key} = ${i}")
        values.append(value)
        
    query = f"""
        UPDATE responsaveis 
        SET {', '.join(set_clauses)}
        WHERE escola_id = $1::uuid AND id = $2::uuid
        RETURNING id
    """
    
    try:
        updated_id = await conn.fetchval(query, *values)
        if not updated_id:
            raise HTTPException(status_code=404, detail="Responsável não encontrado")
            
        ip = request.client.host if request.client else "unknown"
        await registrar_auditoria(
            conn, usuario_id=usuario_id, acao='UPDATE_RESPONSAVEL', 
            detalhes={"id": responsavel_id, "campos_alterados": list(update_data.keys())}, ip_address=ip
        )
            
        return {"message": "Responsável atualizado com sucesso"}
    except asyncpg.UniqueViolationError:
        raise HTTPException(status_code=400, detail="CPF ou E-mail já cadastrado nesta escola.")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{responsavel_id}")
async def deletar_responsavel(
    responsavel_id: str,
    request: Request,
    tenant: dict = Depends(require_role(['admin', 'diretor'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    usuario_id = tenant.get("sub")
    
    query = "DELETE FROM responsaveis WHERE escola_id = $1::uuid AND id = $2::uuid RETURNING id"
    
    try:
        deleted_id = await conn.fetchval(query, escola_id, responsavel_id)
        if not deleted_id:
            raise HTTPException(status_code=404, detail="Responsável não encontrado")
            
        ip = request.client.host if request.client else "unknown"
        await registrar_auditoria(
            conn, usuario_id=usuario_id, acao='DELETE_RESPONSAVEL', 
            detalhes={"id": responsavel_id}, ip_address=ip
        )
            
        return {"message": "Responsável excluído com sucesso"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
