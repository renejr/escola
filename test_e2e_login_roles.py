import pytest
import httpx
import asyncio

AUTH_URL = "http://localhost:8081/auth"
CORE_URL = "http://localhost:8082/core"

@pytest.mark.asyncio
async def test_admin_access():
    async with httpx.AsyncClient() as client:
        # Login como Admin (Escola Alpha)
        resp = await client.post(f"{AUTH_URL}/login", json={
            "email": "admin@escolaalpha.com.br",
            "password": "@Energy12#"
        })
        assert resp.status_code == 200
        data = resp.json()
        token = data["access_token"]
        assert data["role"] == "admin"
        assert data["escola_id"] is not None

        headers = {"Authorization": f"Bearer {token}"}

        # 1. Admin DEVE conseguir acessar o Dashboard (que exige escola_id)
        dash_resp = await client.get(f"{CORE_URL}/dashboard", headers=headers)
        assert dash_resp.status_code == 200

        # 2. Admin NÃO DEVE conseguir acessar rotas do Super Admin
        sa_resp = await client.get(f"{CORE_URL}/superadmin/escolas", headers=headers)
        assert sa_resp.status_code == 403

@pytest.mark.asyncio
async def test_superadmin_access():
    async with httpx.AsyncClient() as client:
        # Login como Super Admin (Global)
        resp = await client.post(f"{AUTH_URL}/login", json={
            "email": "renebmjr@gmail.com",
            "password": "@energy12#"
        })
        assert resp.status_code == 200
        data = resp.json()
        token = data["access_token"]
        assert data["role"] == "superadmin"
        assert data["escola_id"] is None

        headers = {"Authorization": f"Bearer {token}"}

        # 1. Super Admin NÃO DEVE conseguir acessar o Dashboard normal (não possui escola_id)
        # O deps.py exige escola_id para rotas normais
        dash_resp = await client.get(f"{CORE_URL}/dashboard", headers=headers)
        assert dash_resp.status_code == 401

        # 2. Super Admin DEVE conseguir acessar a Sala Cofre
        sa_resp = await client.get(f"{CORE_URL}/superadmin/escolas", headers=headers)
        assert sa_resp.status_code == 200