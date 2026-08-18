from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from pydantic import BaseModel
from typing import List, Optional
from datetime import date
from asyncpg.connection import Connection
from deps import get_db, get_tenant_context, require_role
from services.mercadopago_service import mp_service

router = APIRouter(prefix="/core/financeiro", tags=["Financeiro"])

class ContaReceberCreate(BaseModel):
    aluno_id: Optional[str] = None
    responsavel_id: Optional[str] = None
    valor: float
    data_vencimento: date
    # Removido método de pagamento fixo e tokens de cartão

class ContaReceberResponse(BaseModel):
    id: str
    aluno_id: Optional[str]
    responsavel_id: Optional[str]
    valor: float
    data_vencimento: date
    status: str
    mp_payment_id: Optional[str]
    metodo_pagamento: Optional[str]
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
        SELECT id::text, aluno_id::text, responsavel_id::text, valor, data_vencimento, 
               status, mp_payment_id, metodo_pagamento
        FROM contas_receber
        WHERE escola_id = $1::uuid
        ORDER BY data_vencimento DESC
        """,
        escola_id
    )
    return [dict(r) for r in records]

@router.post("/contas", response_model=ContaReceberResponse)
async def create_conta(
    payload: ContaReceberCreate,
    user: dict = Depends(require_role(['admin', 'diretor', 'secretario'])),
    conn: Connection = Depends(get_db)
):
    escola_id = user.get("escola_id")
    
    # 1. Inserir no banco de dados como 'Pendente'
    query = """
        INSERT INTO contas_receber (escola_id, aluno_id, responsavel_id, valor, data_vencimento, proxima_consulta)
        VALUES ($1::uuid, $2::uuid, $3::uuid, $4, $5, NOW() + INTERVAL '5 minutes')
        RETURNING id::text, aluno_id::text, responsavel_id::text, valor, data_vencimento, status, mp_payment_id, metodo_pagamento, checkout_url, preference_id
    """
    record = await conn.fetchrow(
        query, 
        escola_id, 
        payload.aluno_id, 
        payload.responsavel_id, 
        payload.valor, 
        payload.data_vencimento
    )
    conta = dict(record)

    email_pagador = "renebmjr@gmail.com" 
    descricao = f"Mensalidade Escolar - {conta['id']}"

    try:
        # Gera o Link de Pagamento (Checkout Pro)
        pref_data = await mp_service.criar_preferencia_pagamento(
            valor=payload.valor,
            descricao=descricao,
            id_interno=conta['id'],
            email_pagador=email_pagador
        )
        
        # Atualiza o registro com o Link
        await conn.execute(
            "UPDATE contas_receber SET checkout_url = $1, preference_id = $2 WHERE id = $3::uuid",
            pref_data["checkout_url"], pref_data["preference_id"], conta["id"]
        )
        
        conta["checkout_url"] = pref_data["checkout_url"]
        conta["preference_id"] = pref_data["preference_id"]
        
    except Exception as e:
        print(f"Erro ao integrar com Mercado Pago (Preference): {e}")
        # Mesmo se falhar o Mercado Pago, retorna a conta criada sem a URL, mas sem quebrar a requisição
        conta["checkout_url"] = None
        conta["preference_id"] = None

    return conta