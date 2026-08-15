from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel
import asyncpg
from typing import Optional, List
import json
from datetime import date

from deps import get_db, require_role, registrar_auditoria

router = APIRouter(prefix="/core/alunos", tags=["Alunos"])

class AlunoResponsavelCreate(BaseModel):
    responsavel_id: str
    parentesco: str
    financeiro: bool = False

class AlunoCreate(BaseModel):
    nome: str
    data_nascimento: date
    cpf: Optional[str] = None
    matricula_ra: str
    turma_id: Optional[str] = None
    foto_url: Optional[str] = None
    responsaveis: List[AlunoResponsavelCreate] = []

class AlunoUpdate(BaseModel):
    nome: Optional[str] = None
    data_nascimento: Optional[date] = None
    cpf: Optional[str] = None
    matricula_ra: Optional[str] = None
    turma_id: Optional[str] = None
    foto_url: Optional[str] = None
    ativo: Optional[bool] = None
    responsaveis: Optional[List[AlunoResponsavelCreate]] = None

@router.post("")
async def criar_aluno(
    aluno: AlunoCreate,
    request: Request,
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    usuario_id = tenant.get("sub")
    
    query_aluno = """
        INSERT INTO alunos (
            escola_id, nome, data_nascimento, cpf, matricula_ra, turma_id, foto_url
        ) VALUES (
            $1::uuid, $2, $3, $4, $5, $6::uuid, $7
        ) RETURNING id
    """
    
    query_resp = """
        INSERT INTO aluno_responsavel (escola_id, aluno_id, responsavel_id, parentesco, financeiro)
        VALUES ($1::uuid, $2::uuid, $3::uuid, $4, $5)
    """
    
    try:
        async with conn.transaction():
            aluno_id = await conn.fetchval(
                query_aluno, escola_id, aluno.nome, aluno.data_nascimento, 
                aluno.cpf, aluno.matricula_ra, aluno.turma_id, aluno.foto_url
            )
            
            for resp in aluno.responsaveis:
                await conn.execute(query_resp, escola_id, aluno_id, resp.responsavel_id, resp.parentesco, resp.financeiro)
                
            ip = request.client.host if request.client else "unknown"
            await registrar_auditoria(
                conn, usuario_id=usuario_id, acao='CREATE_ALUNO', 
                detalhes={"id": str(aluno_id), "nome": aluno.nome, "matricula_ra": aluno.matricula_ra}, ip_address=ip
            )
            
        return {"id": str(aluno_id), "message": "Aluno criado com sucesso"}
    except asyncpg.UniqueViolationError:
        raise HTTPException(status_code=400, detail="Matrícula/RA já cadastrado nesta escola.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("")
async def listar_alunos(
    turma_id: Optional[str] = None,
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario', 'professor'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    
    # Resolvendo problema de N+1 queries usando JSON_AGG do PostgreSQL
    base_query = """
        SELECT 
            a.*, 
            t.nome as turma_nome,
            COALESCE(
                (
                    SELECT json_agg(
                        json_build_object(
                            'responsavel_id', ar.responsavel_id,
                            'parentesco', ar.parentesco,
                            'financeiro', ar.financeiro,
                            'responsavel_nome', r.nome
                        )
                    )
                    FROM aluno_responsavel ar
                    JOIN responsaveis r ON ar.responsavel_id = r.id
                    WHERE ar.aluno_id = a.id
                ), '[]'::json
            ) as responsaveis_json
        FROM alunos a 
        LEFT JOIN turmas t ON a.turma_id = t.id 
        WHERE a.escola_id = $1::uuid
    """
    
    if turma_id:
        query = base_query + " AND a.turma_id = $2::uuid ORDER BY a.nome"
        rows = await conn.fetch(query, escola_id, turma_id)
    else:
        query = base_query + " ORDER BY a.nome"
        rows = await conn.fetch(query, escola_id)
        
    result = []
    for row in rows:
        aluno_dict = dict(row)
        aluno_dict['id'] = str(aluno_dict['id'])
        if aluno_dict['turma_id']:
            aluno_dict['turma_id'] = str(aluno_dict['turma_id'])
        if aluno_dict['escola_id']:
            aluno_dict['escola_id'] = str(aluno_dict['escola_id'])
        
        # O json_agg já retorna um JSON em formato de string ou lista de dicts dependendo do driver
        resp_json = aluno_dict.pop('responsaveis_json', '[]')
        if isinstance(resp_json, str):
            responsaveis = json.loads(resp_json)
        else:
            responsaveis = resp_json
            
        aluno_dict['responsaveis'] = responsaveis
        
        # Convert date to string for JSON serialization
        if aluno_dict['data_nascimento']:
            aluno_dict['data_nascimento'] = aluno_dict['data_nascimento'].isoformat()
            
        result.append(aluno_dict)
        
    return result

@router.put("/{aluno_id}")
async def atualizar_aluno(
    aluno_id: str,
    dados: AlunoUpdate,
    request: Request,
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    usuario_id = tenant.get("sub")
    
    update_data = dados.dict(exclude_unset=True)
    responsaveis = update_data.pop('responsaveis', None)
    
    try:
        async with conn.transaction():
            if update_data:
                set_clauses = []
                values = [escola_id, aluno_id]
                
                for i, (key, value) in enumerate(update_data.items(), start=3):
                    set_clauses.append(f"{key} = ${i}")
                    values.append(value)
                    
                query = f"""
                    UPDATE alunos 
                    SET {', '.join(set_clauses)}
                    WHERE escola_id = $1::uuid AND id = $2::uuid
                    RETURNING id
                """
                
                updated_id = await conn.fetchval(query, *values)
                if not updated_id:
                    raise HTTPException(status_code=404, detail="Aluno não encontrado")
            
            if responsaveis is not None:
                # Remove os antigos e insere os novos
                await conn.execute("DELETE FROM aluno_responsavel WHERE aluno_id = $1::uuid", aluno_id)
                query_resp = """
                    INSERT INTO aluno_responsavel (escola_id, aluno_id, responsavel_id, parentesco, financeiro)
                    VALUES ($1::uuid, $2::uuid, $3::uuid, $4, $5)
                """
                for resp in responsaveis:
                    await conn.execute(query_resp, escola_id, aluno_id, resp['responsavel_id'], resp['parentesco'], resp['financeiro'])
            
            ip = request.client.host if request.client else "unknown"
            campos = list(update_data.keys())
            if responsaveis is not None: campos.append('responsaveis')
            
            await registrar_auditoria(
                conn, usuario_id=usuario_id, acao='UPDATE_ALUNO', 
                detalhes={"id": aluno_id, "campos_alterados": campos}, ip_address=ip
            )
            
        return {"message": "Aluno atualizado com sucesso"}
    except asyncpg.UniqueViolationError:
        raise HTTPException(status_code=400, detail="Matrícula/RA já cadastrado nesta escola.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{aluno_id}")
async def deletar_aluno(
    aluno_id: str,
    request: Request,
    tenant: dict = Depends(require_role(['admin', 'diretor'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    usuario_id = tenant.get("sub")
    
    query = "DELETE FROM alunos WHERE escola_id = $1::uuid AND id = $2::uuid RETURNING id"
    
    try:
        deleted_id = await conn.fetchval(query, escola_id, aluno_id)
        if not deleted_id:
            raise HTTPException(status_code=404, detail="Aluno não encontrado")
            
        ip = request.client.host if request.client else "unknown"
        await registrar_auditoria(
            conn, usuario_id=usuario_id, acao='DELETE_ALUNO', 
            detalhes={"id": aluno_id}, ip_address=ip
        )
            
        return {"message": "Aluno excluído com sucesso"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
