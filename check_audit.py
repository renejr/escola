import asyncio
import asyncpg

async def run():
    conn = await asyncpg.connect('postgresql://postgres:%40energy12%23@localhost:5432/saas_escolar')
    res = await conn.fetch("SELECT column_name FROM information_schema.columns WHERE table_name = 'audit_logs'")
    for r in res:
        print(r['column_name'])
    await conn.close()

if __name__ == '__main__':
    asyncio.run(run())