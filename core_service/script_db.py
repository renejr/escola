import asyncio
from dotenv import load_dotenv
load_dotenv()
import os
import asyncpg

async def alter_tables():
    DATABASE_URL = os.getenv("DATABASE_URL")
    if not DATABASE_URL:
        print("DATABASE_URL não encontrado!")
        return
        
    conn = await asyncpg.connect(DATABASE_URL)
    try:
        await conn.execute('''
            ALTER TABLE contas_receber 
            ADD COLUMN IF NOT EXISTS tentativas_consulta INT DEFAULT 0,
            ADD COLUMN IF NOT EXISTS proxima_consulta TIMESTAMP,
            ADD COLUMN IF NOT EXISTS card_id VARCHAR(255),
            ADD COLUMN IF NOT EXISTS customer_id VARCHAR(255);
        ''')
        print('Tabela contas_receber alterada com sucesso.')
        
        await conn.execute('''
            ALTER TABLE responsaveis 
            ADD COLUMN IF NOT EXISTS mp_customer_id VARCHAR(255);
        ''')
        print('Tabela responsaveis alterada com sucesso.')
    except Exception as e:
        print('ERRO:', e)
    finally:
        await conn.close()

if __name__ == "__main__":
    asyncio.run(alter_tables())
