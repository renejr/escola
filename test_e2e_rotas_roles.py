import pytest
import httpx
import asyncio

AUTH_URL = "http://localhost:8081/auth"
CORE_URL = "http://localhost:8082/core"

@pytest.mark.asyncio
async def test_admin_rotas_access():
    async with httpx.AsyncClient() as client:
        # 1. Login como Admin (Escola Alpha)
        resp = await client.post(f"{AUTH_URL}/login", json={
            "email": "admin@escolaalpha.com.br",
            "password": "123456"
        })
        assert resp.status_code == 200, f"Falha no login Admin: {resp.text}"
        data = resp.json()
        token = data["access_token"]
        assert data["role"] == "admin"
        assert data["escola_id"] is not None

        headers = {"Authorization": f"Bearer {token}"}

        # 2. Acesso ao Dashboard (Permitido)
        dash_resp = await client.get(f"{CORE_URL}/dashboard", headers=headers)
        assert dash_resp.status_code == 200, "Admin não conseguiu acessar o Dashboard"

        # 3. Acesso à rota de professores (Permitido para admin)
        prof_resp = await client.get(f"{CORE_URL}/professores", headers=headers)
        assert prof_resp.status_code == 200, "Admin não conseguiu listar professores"

        # 4. Acesso à Sala Cofre / Super Admin (Proibido)
        sa_resp = await client.get(f"{CORE_URL}/superadmin/escolas", headers=headers)
        assert sa_resp.status_code == 403, "Admin não deveria acessar a lista de escolas global"

        kpis_resp = await client.get(f"{CORE_URL}/superadmin/kpis", headers=headers)
        assert kpis_resp.status_code == 403, "Admin não deveria acessar os KPIs globais"

@pytest.mark.asyncio
async def test_superadmin_rotas_access():
    async with httpx.AsyncClient() as client:
        # 1. Login como Super Admin (Global)
        resp = await client.post(f"{AUTH_URL}/login", json={
            "email": "renebmjr@gmail.com",
            "password": "@energy12#"
        })
        assert resp.status_code == 200, f"Falha no login Super Admin: {resp.text}"
        data = resp.json()
        token = data["access_token"]
        assert data["role"] == "superadmin"
        assert data["escola_id"] is None

        headers = {"Authorization": f"Bearer {token}"}

        # 2. Acesso ao Dashboard normal (Proibido - exige escola_id)
        dash_resp = await client.get(f"{CORE_URL}/dashboard", headers=headers)
        assert dash_resp.status_code == 401, "Super Admin não deveria acessar dashboard normal sem escola_id"

        # 3. Acesso à rota de professores (Proibido - exige escola_id)
        prof_resp = await client.get(f"{CORE_URL}/professores", headers=headers)
        assert prof_resp.status_code == 401, "Super Admin não deveria acessar listar professores sem escola_id"

        # 4. Acesso à Sala Cofre / Super Admin (Permitido)
        sa_resp = await client.get(f"{CORE_URL}/superadmin/escolas", headers=headers)
        assert sa_resp.status_code == 200, "Super Admin não conseguiu listar escolas"

        kpis_resp = await client.get(f"{CORE_URL}/superadmin/kpis", headers=headers)
        assert kpis_resp.status_code == 200, "Super Admin não conseguiu acessar KPIs"
