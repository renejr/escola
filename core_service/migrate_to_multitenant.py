import asyncio
import asyncpg
import os
from dotenv import load_dotenv

load_dotenv()

async def main():
    conn = await asyncpg.connect(os.getenv("DATABASE_URL"))
    
    print("\n[+] Iniciando injeção do Tenant Mock...")
    
    # 2. INJEÇÃO DA ESCOLA MOCK E CAPTURA DO ID
    tenant_id = await conn.fetchval("""
        SELECT id FROM escolas WHERE cnpj = '00.000.000/0001-00'
    """)
    
    if not tenant_id:
        tenant_id = await conn.fetchval("""
            INSERT INTO escolas (razao_social, nome_fantasia, cnpj, nome)
            VALUES ('Escola Alpha Mock', 'Escola Alpha', '00.000.000/0001-00', 'Escola Alpha Mock')
            RETURNING id
        """)
    
    print(f"\n==========================================")
    print(f">>> TENANT_ID CAPTURADO: {tenant_id} <<<")
    print(f"==========================================\n")
    
    # 3. VARREDURA E ATUALIZAÇÃO DAS TABELAS
    tabelas_alvo = [
        'usuarios', 
        'turmas', 
        'responsaveis', 
        'alunos', 
        'materias', 
        'grade_curricular', 
        'eventos_agenda',
        'notificacoes'
    ]
    
    for tabela in tabelas_alvo:
        print(f"--- Analisando tabela: {tabela} ---")
        
        # a) Verifica se a tabela existe
        tabela_existe = await conn.fetchval("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_name = $1
            )
        """, tabela)
        
        if not tabela_existe:
            print(f"[!] Tabela '{tabela}' não encontrada no banco. Pulando.\n")
            continue
            
        # Verifica se a coluna escola_id existe
        coluna_existe = await conn.fetchval("""
            SELECT EXISTS (
                SELECT FROM information_schema.columns 
                WHERE table_name = $1 AND column_name = 'escola_id'
            )
        """, tabela)
        
        if not coluna_existe:
            print(f"[*] Criando coluna 'escola_id' na tabela '{tabela}'...")
            await conn.execute(f"ALTER TABLE {tabela} ADD COLUMN escola_id UUID")
        else:
            print(f"[*] Coluna 'escola_id' já existe na tabela '{tabela}'.")
            
        # b) Update dos registros onde escola_id IS NULL
        result = await conn.execute(f"UPDATE {tabela} SET escola_id = $1 WHERE escola_id IS NULL", tenant_id)
        print(f"[*] Registros atualizados: {result}")
        
        # c) Criação de FK
        fk_name = f"fk_{tabela}_escola_id"
        fk_existe = await conn.fetchval("""
            SELECT EXISTS (
                SELECT 1 FROM pg_constraint WHERE conname = $1
            )
        """, fk_name)
        
        if not fk_existe:
            print(f"[*] Adicionando Foreign Key '{fk_name}' na tabela '{tabela}'...")
            try:
                await conn.execute(f"""
                    ALTER TABLE {tabela} 
                    ADD CONSTRAINT {fk_name} 
                    FOREIGN KEY (escola_id) REFERENCES escolas(id)
                """)
            except Exception as e:
                print(f"[!] Falha ao adicionar FK: {e}")
        else:
            print(f"[*] Foreign Key '{fk_name}' já existe.")
            
        # d) Set NOT NULL
        try:
            await conn.execute(f"ALTER TABLE {tabela} ALTER COLUMN escola_id SET NOT NULL")
            print(f"[*] Coluna 'escola_id' blindada como NOT NULL na tabela '{tabela}'.\n")
        except Exception as e:
            print(f"[!] Aviso ao definir NOT NULL: {e}\n")

    await conn.close()
    print("=== MIGRAÇÃO MULTITENANT FINALIZADA COM SUCESSO ===")

if __name__ == "__main__":
    asyncio.run(main())