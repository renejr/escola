import os
import mercadopago
from typing import Dict, Any

class MercadoPagoService:
    def __init__(self):
        token = os.getenv("MP_ACCESS_TOKEN")
        if not token:
            print("AVISO: MP_ACCESS_TOKEN não configurado no .env")
        self.sdk = mercadopago.SDK(token) if token else None

    async def gerar_cobranca_pix(
        self, 
        valor: float, 
        email_pagador: str, 
        descricao: str, 
        id_interno: str
    ) -> Dict[str, Any]:
        """
        Gera uma cobrança PIX via Mercado Pago.
        Retorna um dicionário com o ID do pagamento, QR Code (Base64) e o ticket_url (Copia e Cola).
        """
        if not self.sdk:
            raise Exception("SDK do Mercado Pago não inicializado. Verifique o MP_ACCESS_TOKEN.")

        payment_data = {
            "transaction_amount": float(valor),
            "description": descricao,
            "payment_method_id": "pix",
            "payer": {
                "email": email_pagador
            },
            "external_reference": id_interno
        }

        # Em um ambiente real, isso seria executado em um ThreadPool ou o SDK do MP teria suporte a async nativo
        # O SDK oficial do Mercado Pago para Python atualmente é síncrono.
        response = self.sdk.payment().create(payment_data)
        
        if response["status"] != 201:
            raise Exception(f"Erro ao gerar PIX no Mercado Pago: {response.get('response')}")

        payment_info = response["response"]
        
        return {
            "mp_payment_id": str(payment_info["id"]),
            "qr_code_base64": payment_info["point_of_interaction"]["transaction_data"]["qr_code_base64"],
            "qr_code": payment_info["point_of_interaction"]["transaction_data"]["qr_code"],
            "ticket_url": payment_info["point_of_interaction"]["transaction_data"]["ticket_url"]
        }

    async def consultar_status_pagamento(self, payment_id: str) -> str:
        """
        Consulta o status real de um pagamento no Mercado Pago.
        """
        if not self.sdk:
            raise Exception("SDK do Mercado Pago não inicializado.")
            
        response = self.sdk.payment().get(payment_id)
        if response["status"] != 200:
            raise Exception("Erro ao consultar pagamento no Mercado Pago")
            
        return response["response"]["status"]

# Instância Singleton
mp_service = MercadoPagoService()
