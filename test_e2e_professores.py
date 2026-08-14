import asyncio
import httpx
import os

# Simulando um token JWT (precisamos do token de um admin ou diretor para testar)
# Como o sistema pode exigir um token real, podemos gerar um token válido usando a secret.
import jwt
from datetime import datetime, timedelta

JWT_SECRET = "7b5a8e4f1a2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e"
ALGORITHM = "HS256"

# Vamos pegar o escola_id do tenant admin. Para não chutar o UUID, vou conectar no banco e pegar um.
import asyncpg
DB_URL = "postgresql://postgres:%40energy12%23@localhost:5432/saas_escolar"

async def run_e2e_test():
    print("Iniciando Teste E2E de Professores...")
    
    conn = await asyncpg.connect(DB_URL)
    escola = await conn.fetchrow("SELECT id FROM escolas LIMIT 1")
    escola_id = str(escola['id']) if escola else "00000000-0000-0000-0000-000000000000"
    
    admin = await conn.fetchrow("SELECT id FROM usuarios WHERE papel = 'admin' LIMIT 1")
    admin_id = str(admin['id']) if admin else "00000000-0000-0000-0000-000000000000"
    await conn.close()

    # Gera token de admin
    payload = {
        "sub": admin_id,
        "escola_id": escola_id,
        "role": "admin",
        "exp": datetime.utcnow() + timedelta(minutes=60)
    }
    token = jwt.encode(payload, JWT_SECRET, algorithm=ALGORITHM)
    
    headers = {"Authorization": f"Bearer {token}"}
    base_url = "http://localhost:8082/core/professores"
    
    async with httpx.AsyncClient() as client:
        # 1. CREATE
        print("\n1. Testando POST /core/professores...")
        prof_data = {
            "nome": "Professor Teste E2E",
            "cpf": "11122233344",
            "email": "prof.test.e2e@escola.com",
            "celular": "11999999999"
        }
        resp = await client.post(base_url, json=prof_data, headers=headers)
        if resp.status_code == 400 and "já cadastrado" in resp.text:
            print("Professor já existia, vamos deletar e recriar.")
            # Buscar e deletar via banco seria mais limpo, mas vamos usar um e-mail aleatorio
            import time
            prof_data["email"] = f"prof.test.{int(time.time())}@escola.com"
            resp = await client.post(base_url, json=prof_data, headers=headers)
            
        assert resp.status_code == 200, f"Erro POST: {resp.text}"
        created_prof = resp.json()
        print(f"Sucesso! Criado: {created_prof}")
        assert created_prof["celular"] == "11999999999", "Celular não persistido corretamente"
        assert created_prof["ativo"] == True, "Ativo não defaultou para True"
        
        prof_id = created_prof["id"]
        
        # 2. READ
        print("\n2. Testando GET /core/professores...")
        resp = await client.get(base_url, headers=headers)
        assert resp.status_code == 200, f"Erro GET: {resp.text}"
        profs = resp.json()
        found = next((p for p in profs if p["id"] == prof_id), None)
        assert found is not None, "Professor recém criado não encontrado na listagem"
        print(f"Sucesso! Professor encontrado na listagem. Total: {len(profs)}")
        
        # 3. UPDATE
        print("\n3. Testando PUT /core/professores/{id}...")
        update_data = {
            "nome": "Professor Teste E2E Editado",
            "cpf": "11122233344",
            "email": prof_data["email"],
            "celular": "11888888888"
        }
        resp = await client.put(f"{base_url}/{prof_id}", json=update_data, headers=headers)
        assert resp.status_code == 200, f"Erro PUT: {resp.text}"
        updated_prof = resp.json()
        print(f"Sucesso! Atualizado: {updated_prof}")
        assert updated_prof["celular"] == "11888888888", "Celular não atualizado corretamente"
        
        # 4. DELETE (Inativar)
        print("\n4. Testando DELETE /core/professores/{id}...")
        resp = await client.delete(f"{base_url}/{prof_id}", headers=headers)
        assert resp.status_code == 200, f"Erro DELETE: {resp.text}"
        print("Sucesso! Professor inativado.")

    print("\n✅ Todos os testes E2E passaram com sucesso. O esquema do banco e as rotas estão operantes.")

if __name__ == "__main__":
    asyncio.run(run_e2e_test())