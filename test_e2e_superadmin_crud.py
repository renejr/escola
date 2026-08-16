import asyncio
import httpx
import pytest
import uuid
import asyncpg
import os
from dotenv import load_dotenv

load_dotenv("core_service/.env")

AUTH_URL = "http://localhost:8081/auth"
CORE_URL = "http://localhost:8082/core"
DB_URL = "postgresql://postgres:%40energy12%23@localhost:5432/saas_escolar"

@pytest.mark.asyncio
async def test_superadmin_crud_fluxo_completo():
    async with httpx.AsyncClient() as client:
        # 1. Login como Super Admin
        resp = await client.post(f"{AUTH_URL}/login", json={
            "email": "renebmjr@gmail.com",
            "password": "@energy12#"
        })
        assert resp.status_code == 200, f"Falha no login: {resp.text}"
        data = resp.json()
        token = data["access_token"]
        
        headers = {"Authorization": f"Bearer {token}"}
        
        # 2. Listar KPIs
        resp_kpis = await client.get(f"{CORE_URL}/superadmin/kpis", headers=headers)
        assert resp_kpis.status_code == 200, f"Falha ao listar KPIs: {resp_kpis.text}"
        
        # 3. Criar uma nova Escola Mock e seu primeiro Admin
        mock_cnpj = f"99.999.999/{str(uuid.uuid4().int)[:4]}-99"
        mock_admin_email = f"admin_{str(uuid.uuid4().int)[:4]}@e2e.com"
        
        nova_escola = {
            "razao_social": "Escola de Teste E2E",
            "nome_fantasia": "Teste E2E",
            "cnpj": mock_cnpj,
            "email_contato": "teste@e2e.com",
            "telefone": "11999999999",
            "admin_nome": "Gestor E2E",
            "admin_email": mock_admin_email,
            "admin_senha": "senhaforte123"
        }
        
        resp_create = await client.post(f"{CORE_URL}/superadmin/escolas", json=nova_escola, headers=headers)
        assert resp_create.status_code == 200, f"Falha ao criar escola e admin: {resp_create.text}"
        escola_id = resp_create.json()["id"]
        
        # 4. Listar Escolas (garantir que a recém-criada está lá)
        resp_list = await client.get(f"{CORE_URL}/superadmin/escolas", headers=headers)
        assert resp_list.status_code == 200, f"Falha ao listar escolas: {resp_list.text}"
        escolas = resp_list.json()
        assert any(e["id"] == escola_id for e in escolas), "Escola criada não foi listada"
        
        # 5. Atualizar Escola
        update_data = {
            "razao_social": "Escola de Teste E2E Atualizada",
            "nome_fantasia": "Teste E2E",
            "cnpj": mock_cnpj,
            "email_contato": "atualizado@e2e.com",
            "telefone": "11888888888"
        }
        resp_update = await client.put(f"{CORE_URL}/superadmin/escolas/{escola_id}", json=update_data, headers=headers)
        assert resp_update.status_code == 200, f"Falha ao atualizar escola: {resp_update.text}"
        
        # 6. Toggle Status
        resp_toggle = await client.patch(f"{CORE_URL}/superadmin/escolas/{escola_id}/toggle-status", headers=headers)
        assert resp_toggle.status_code == 200, f"Falha ao fazer toggle do status: {resp_toggle.text}"
        
        # 8. Validar se o usuário Admin foi criado
        conn = await asyncpg.connect(DB_URL)
        try:
            # Puxa o último log do superadmin
            query_audit = """
                    SELECT acao, escola_id
                    FROM audit_logs
                    WHERE usuario_id::uuid = (SELECT id::uuid FROM usuarios WHERE email = 'renebmjr@gmail.com')
                    ORDER BY criado_em DESC
                    LIMIT 1
                """
            log = await conn.fetchrow(query_audit)
            assert log is not None, "Nenhum log de auditoria encontrado"
            assert log['escola_id'] is not None, "Log de auditoria foi gravado sem escola_id (NOT NULL bypass)"
            
            # Valida o admin_usuario inserido
            query_usuario = "SELECT id, papel, escola_id FROM usuarios WHERE email = $1"
            admin_user = await conn.fetchrow(query_usuario, mock_admin_email)
            assert admin_user is not None, "Usuário admin não foi inserido no banco."
            assert admin_user['papel'] == 'admin', "O papel do novo usuário não é 'admin'."
            assert str(admin_user['escola_id']) == str(escola_id), "O escola_id do admin não corresponde à escola criada."
        finally:
            await conn.close()
            
        print("Teste E2E Completo, Transação e Auditoria validados com sucesso!")