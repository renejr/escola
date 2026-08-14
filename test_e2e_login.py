import asyncio
import httpx
import json

async def test_login():
    url = "http://localhost:8001/auth/login"
    payload = {
        "email": "admin@escolaalpha.com.br",
        "password": "123456"
    }
    
    print(f"🚀 Iniciando Teste E2E de Login...")
    print(f"📡 Endpoint: {url}")
    print(f"📦 Payload: {json.dumps(payload)}")
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(url, json=payload, timeout=5.0)
            
            print(f"\n📥 Status Code Recebido: {response.status_code}")
            
            if response.status_code == 200:
                print("✅ SUCESSO: Login efetuado e Token JWT gerado!")
                print(f"🔑 Resposta: {response.json()}")
            else:
                print(f"❌ FALHA: Erro no servidor.")
                print(f"Detalhes: {response.text}")
                
    except Exception as e:
        print(f"⚠️ ERRO DE CONEXÃO: {e}")

if __name__ == "__main__":
    asyncio.run(test_login())