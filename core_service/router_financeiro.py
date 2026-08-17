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
    metodo_pagamento: str = "pix"

class ContaReceberResponse(BaseModel):
    id: str
    aluno_id: Optional[str]
    responsavel_id: Optional[str]
    valor: float
    data_vencimento: date
    status: str
    mp_payment_id: Optional[str]
    metodo_pagamento: Optional[str]
    qr_code_base64: Optional[str] = None
    qr_code_copia_cola: Optional[str] = None

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
        INSERT INTO contas_receber (escola_id, aluno_id, responsavel_id, valor, data_vencimento, metodo_pagamento)
        VALUES ($1::uuid, $2::uuid, $3::uuid, $4, $5, $6)
        RETURNING id::text, aluno_id::text, responsavel_id::text, valor, data_vencimento, status, mp_payment_id, metodo_pagamento
    """
    record = await conn.fetchrow(
        query, 
        escola_id, 
        payload.aluno_id, 
        payload.responsavel_id, 
        payload.valor, 
        payload.data_vencimento, 
        payload.metodo_pagamento
    )
    conta = dict(record)

    # Se o método for PIX, já gera a cobrança no Mercado Pago
    if payload.metodo_pagamento.lower() == 'pix':
        # TODO: Buscar email real do pagador (aluno ou responsavel)
        email_pagador = "pagador@sandbox.com" 
        descricao = f"Mensalidade Escolar - {conta['id']}"
        
        try:
            mp_data = await mp_service.gerar_cobranca_pix(
                valor=payload.valor,
                email_pagador=email_pagador,
                descricao=descricao,
                id_interno=conta['id']
            )
            
            # Atualiza o registro com o ID do Mercado Pago
            await conn.execute(
                "UPDATE contas_receber SET mp_payment_id = $1 WHERE id = $2::uuid",
                mp_data["mp_payment_id"], conta["id"]
            )
            
            conta["mp_payment_id"] = mp_data["mp_payment_id"]
            conta["qr_code_base64"] = mp_data["qr_code_base64"]
            conta["qr_code_copia_cola"] = mp_data["qr_code"]
            
        except Exception as e:
            # Em caso de falha na integração, mantemos a conta criada mas sem os dados do MP
            print(f"Erro ao integrar com Mercado Pago: {e}")

    return conta