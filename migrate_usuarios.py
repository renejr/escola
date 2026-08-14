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
        await conn.execute("ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS celular VARCHAR(20);")
        print("Coluna 'celular' adicionada (se não existia).")
        
        await conn.execute("ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS ativo BOOLEAN DEFAULT TRUE;")
        print("Coluna 'ativo' adicionada (se não existia).")
    except Exception as e:
        print(f"Erro ao alterar a tabela: {e}")
    finally:
        await conn.close()
        print("Conexão encerrada.")

if __name__ == "__main__":
    asyncio.run(main())