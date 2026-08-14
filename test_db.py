import asyncio
import asyncpg
import os
from dotenv import load_dotenv

load_dotenv("d:/escola/core_service/.env")

async def test_db():
    conn = await asyncpg.connect(os.getenv("DATABASE_URL"))
    try:
        # Check turmas columns
        rows = await conn.fetch("SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'turmas'")
        for r in rows:
            print(r['column_name'], r['data_type'], r['is_nullable'])
    finally:
        await conn.close()

asyncio.run(test_db())