import os
import httpx
from dotenv import load_dotenv

load_dotenv()

API_URL = os.getenv("EVOLUTION_API_URL", "http://localhost:8080")
API_KEY = os.getenv("EVOLUTION_API_KEY", "chave_generica")
INSTANCE = os.getenv("EVOLUTION_INSTANCE_NAME", "escola_alpha")

headers = {
    "apikey": API_KEY,
    "Content-Type": "application/json"
}

async def obter_status_conexao():
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(f"{API_URL}/instance/connectionState/{INSTANCE}", headers=headers)
            if response.status_code == 200:
                return response.json()
            return {"instance": {"state": "disconnected"}}
        except Exception as e:
            print(f"Erro ao obter status do wpp: {e}")
            return {"instance": {"state": "error", "message": str(e)}}

async def gerar_qr_code():
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(f"{API_URL}/instance/connect/{INSTANCE}", headers=headers)
            if response.status_code == 200:
                return response.json()
            return {"error": "Falha ao gerar QR Code"}
        except Exception as e:
            return {"error": str(e)}

async def enviar_mensagem_whatsapp(numero: str, mensagem: str):
    payload = {
        "number": numero,
        "options": {
            "delay": 1200,
            "presence": "composing"
        },
        "textMessage": {
            "text": mensagem
        }
    }
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(f"{API_URL}/message/sendText/{INSTANCE}", json=payload, headers=headers)
            print(f"SIMULAÇÃO/REAL WPP -> Enviando para {numero}: {mensagem} | Status: {response.status_code}")
            return response.json()
        except Exception as e:
            print(f"Falha ao enviar whatsapp: {e}")
            return None
