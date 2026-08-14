import asyncio
import asyncpg

async def main():
    conn = await asyncpg.connect(
        user='postgres',
        password='@energy12#',
        database='saas_escolar',
        host='localhost',
        port=5432
    )
    print("Conectado ao banco de dados.")
    
    try:
        await conn.execute("ALTER TABLE turmas ADD COLUMN IF NOT EXISTS turno VARCHAR(50);")
        await conn.execute("ALTER TABLE turmas ADD COLUMN IF NOT EXISTS ano_letivo VARCHAR(20);")
        await conn.execute("ALTER TABLE turmas ADD COLUMN IF NOT EXISTS sala VARCHAR(50);")
        await conn.execute("ALTER TABLE turmas ADD COLUMN IF NOT EXISTS ativo BOOLEAN DEFAULT TRUE;")
        print("Colunas 'turno', 'ano_letivo', 'sala', 'ativo' adicionadas (se não existiam) em 'turmas'.")
    except Exception as e:
        print(f"Erro ao alterar a tabela turmas: {e}")
    finally:
        await conn.close()
        print("Conexão encerrada.")

if __name__ == "__main__":
    asyncio.run(main())