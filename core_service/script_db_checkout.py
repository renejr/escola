import asyncio
from dotenv import load_dotenv
load_dotenv()
import os
import asyncpg

async def alter_tables_checkout():
    DATABASE_URL = os.getenv("DATABASE_URL")
    if not DATABASE_URL:
        print("DATABASE_URL não encontrado!")
        return
        
    conn = await asyncpg.connect(DATABASE_URL)
    try:
        await conn.execute('''
            ALTER TABLE contas_receber 
            ADD COLUMN IF NOT EXISTS checkout_url VARCHAR(1024),
            ADD COLUMN IF NOT EXISTS preference_id VARCHAR(255);
        ''')
        print('Tabela contas_receber alterada com sucesso para Checkout Pro.')
        
    except Exception as e:
        print('ERRO:', e)
    finally:
        await conn.close()

if __name__ == "__main__":
    asyncio.run(alter_tables_checkout())
