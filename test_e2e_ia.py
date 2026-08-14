import asyncio
import httpx
import json

async def test_ia():
    print("Testando rota do RAG via Gateway...")
    
    # 1. Faz o login para pegar o token
    login_data = {"email": "admin@escolaalpha.com.br", "password": "123456"}
    async with httpx.AsyncClient() as client:
        print("Fazendo login...")
        login_res = await client.post("http://localhost:8000/auth/login", json=login_data)
        
        if login_res.status_code != 200:
            print(f"Falha no login: {login_res.status_code} - {login_res.text}")
            return
            
        token = login_res.json().get("access_token")
        print(f"Token obtido: {token[:20]}...")
        
        # 2. Faz a pergunta
        headers = {"Authorization": f"Bearer {token}"}
        payload = {"pergunta": "Quais são as regras da escola?"}
        
        print("Enviando pergunta para a IA... (pode demorar)")
        try:
            # timeout longo para não quebrar no teste
            ia_res = await client.post(
                "http://localhost:8000/core/ia/perguntar", 
                json=payload, 
                headers=headers,
                timeout=60.0
            )
            print(f"Status IA: {ia_res.status_code}")
            print(f"Resposta: {ia_res.text}")
        except Exception as e:
            print(f"Erro ao chamar Gateway: {e}")

if __name__ == "__main__":
    asyncio.run(test_ia())