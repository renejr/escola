from fastapi import APIRouter, Depends, Request
from asyncpg.connection import Connection
from deps import get_db
from services.mercadopago_service import mp_service

router = APIRouter(prefix="/core/webhooks", tags=["Webhooks"])

@router.post("/mercadopago")
async def mercadopago_webhook(
    request: Request,
    conn: Connection = Depends(get_db)
):
    """
    Endpoint para receber notificações de pagamento do Mercado Pago.
    A URL deste endpoint deve ser configurada no painel do Mercado Pago.
    """
    payload = await request.json()
    
    # O Mercado Pago pode enviar diferentes formatos dependendo da configuração (IPN vs Webhooks).
    # Geralmente, a ação vem no campo 'action' e o ID do pagamento no 'data.id'
    
    action = payload.get("action")
    topic = payload.get("topic")
    
    # Valida se é uma notificação de pagamento (Webhooks envia action="payment.created/updated")
    if action and action.startswith("payment."):
        data = payload.get("data", {})
        payment_id = data.get("id")
    elif topic == "payment":
        # Formato antigo (IPN) envia topic="payment" e resource=".../id"
        resource = payload.get("resource", "")
        payment_id = resource.split("/")[-1] if resource else None
    else:
        # Outro tipo de notificação que não nos interessa processar agora
        return {"status": "ignored"}

    if not payment_id:
        return {"status": "error", "message": "ID do pagamento não encontrado no payload"}

    try:
        # Consulta o status real no Mercado Pago para evitar spoofing
        status = await mp_service.consultar_status_pagamento(str(payment_id))
        
        if status == "approved":
            # Dá baixa na conta
            query = """
                UPDATE contas_receber 
                SET status = 'Pago' 
                WHERE mp_payment_id = $1 AND status != 'Pago'
            """
            await conn.execute(query, str(payment_id))
            
            # Aqui poderíamos engatilhar a geração de Recibo (NFS-e) 
            # e envio de email de confirmação.
            
            return {"status": "success", "message": "Pagamento aprovado e conta baixada"}
            
        elif status in ["cancelled", "rejected", "refunded"]:
            query = """
                UPDATE contas_receber 
                SET status = 'Cancelado' 
                WHERE mp_payment_id = $1
            """
            await conn.execute(query, str(payment_id))
            return {"status": "success", "message": f"Pagamento atualizado para {status}"}
            
        return {"status": "success", "message": f"Pagamento recebido mas pendente (Status: {status})"}

    except Exception as e:
        print(f"Erro ao processar webhook do Mercado Pago: {e}")
        # Retornamos 200 pro MP não ficar tentando reenviar infinitamente se for erro de regra de negócio
        return {"status": "error", "message": str(e)}
