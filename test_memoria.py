import asyncio
import httpx

async def test_memoria():
    print("Fazendo login...")
    login_data = {"email": "admin@escolaalpha.com.br", "password": "123456"}
    async with httpx.AsyncClient() as client:
        login_res = await client.post("http://localhost:8000/auth/login", json=login_data)
        if login_res.status_code != 200:
            print("Falha no login:", login_res.text)
            return
        
        token = login_res.json().get("access_token")
        
        print("Enviando memória...")
        headers = {"Authorization": f"Bearer {token}"}
        payload = {
            "texto": "A escola Alpha não permite o uso de bonés.",
            "tipo_contexto": "Regimento Escolar"
        }
        
        res = await client.post(
            "http://localhost:8000/core/ia/memoria",
            json=payload,
            headers=headers,
            timeout=60.0
        )
        
        print(f"Status: {res.status_code}")
        print(f"Body: {res.text}")

if __name__ == "__main__":
    asyncio.run(test_memoria())