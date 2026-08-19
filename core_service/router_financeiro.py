from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import date
from dateutil.relativedelta import relativedelta
from asyncpg.connection import Connection
from deps import get_db, get_tenant_context, require_role
from services.mercadopago_service import mp_service

router = APIRouter(prefix="/core/financeiro", tags=["Financeiro"])

class ContaReceberCreate(BaseModel):
    aluno_id: Optional[str] = None
    responsavel_id: Optional[str] = None
    valor_bruto: float
    desconto: float = 0.0
    data_vencimento: date
    parcelas: int = Field(default=1, ge=1, le=12)
    motivo: str
    descricao: str

class ContaReceberResponse(BaseModel):
    id: str
    aluno_id: Optional[str]
    responsavel_id: Optional[str]
    valor_bruto: float
    desconto: float
    valor: float # valor liquido
    data_vencimento: date
    status: str
    motivo: Optional[str]
    descricao: Optional[str]
    parcela_atual: int
    total_parcelas: int
    checkout_url: Optional[str] = None
    preference_id: Optional[str] = None

@router.get("/contas", response_model=List[ContaReceberResponse])
async def list_contas(
    user: dict = Depends(require_role(['admin', 'diretor', 'secretario'])),
    conn: Connection = Depends(get_db)
):
    escola_id = user.get("escola_id")
    records = await conn.fetch(
        """
        SELECT id::text, aluno_id::text, responsavel_id::text, 
               valor_bruto, desconto, valor, data_vencimento, 
               status, motivo, descricao, parcela_atual, total_parcelas,
               checkout_url, preference_id
        FROM contas_receber
        WHERE escola_id = $1::uuid
        ORDER BY data_vencimento DESC
        """,
        escola_id
    )
    return [dict(r) for r in records]

@router.post("/contas", response_model=List[ContaReceberResponse])
async def create_conta_lote(
    payload: ContaReceberCreate,
    user: dict = Depends(require_role(['admin', 'diretor', 'secretario'])),
    conn: Connection = Depends(get_db)
):
    escola_id = user.get("escola_id")
    
    # Se for um Carnê, o valor bruto informado deve ser dividido pelo número de parcelas
    valor_bruto_por_parcela = round(payload.valor_bruto / payload.parcelas, 2)
    desconto_por_parcela = round(payload.desconto / payload.parcelas, 2)
    
    valor_liquido_por_parcela = valor_bruto_por_parcela - desconto_por_parcela
    if valor_liquido_por_parcela < 0:
        valor_liquido_por_parcela = 0.0

    # Puxar email do responsável ou aluno
    email_pagador = "renebmjr@gmail.com" # TODO: Substituir por query real se necessário
    
    contas_criadas = []
    
    # Iniciar transação atômica para o lote de parcelas
    async with conn.transaction():
        for i in range(payload.parcelas):
            parcela_atual = i + 1
            vencimento_parcela = payload.data_vencimento + relativedelta(months=i)
            
            query = """
                INSERT INTO contas_receber (
                    escola_id, aluno_id, responsavel_id, 
                    valor_bruto, desconto, valor, data_vencimento,
                    motivo, descricao, parcela_atual, total_parcelas
                )
                VALUES ($1::uuid, $2::uuid, $3::uuid, $4, $5, $6, $7, $8, $9, $10, $11)
                RETURNING id::text, aluno_id::text, responsavel_id::text, 
                          valor_bruto, desconto, valor, data_vencimento, 
                          status, motivo, descricao, parcela_atual, total_parcelas
            """
            record = await conn.fetchrow(
                query, 
                escola_id, 
                payload.aluno_id, 
                payload.responsavel_id, 
                valor_bruto_por_parcela,
                desconto_por_parcela,
                valor_liquido_por_parcela, 
                vencimento_parcela,
                payload.motivo,
                payload.descricao,
                parcela_atual,
                payload.parcelas
            )
            conta = dict(record)

            descricao_mp = f"{payload.descricao} (Parcela {parcela_atual}/{payload.parcelas})"
            
            try:
                # Gera o Link de Pagamento (Checkout Pro) com data de expiração
                pref_data = await mp_service.criar_preferencia_pagamento(
                    valor=valor_liquido_por_parcela,
                    descricao=descricao_mp,
                    id_interno=conta['id'],
                    email_pagador=email_pagador,
                    data_vencimento=vencimento_parcela
                )
                
                # Atualiza o registro com o Link
                await conn.execute(
                    "UPDATE contas_receber SET checkout_url = $1, preference_id = $2 WHERE id = $3::uuid",
                    pref_data["checkout_url"], pref_data["preference_id"], conta["id"]
                )
                
                conta["checkout_url"] = pref_data["checkout_url"]
                conta["preference_id"] = pref_data["preference_id"]
                
            except Exception as e:
                print(f"Erro ao integrar com Mercado Pago (Preference) na parcela {parcela_atual}: {e}")
                conta["checkout_url"] = None
                conta["preference_id"] = None
                
            contas_criadas.append(conta)

    return contas_criadas
