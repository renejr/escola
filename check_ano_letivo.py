import asyncio
import asyncpg

async def main():
    conn = await asyncpg.connect('postgresql://postgres:%40energy12%23@localhost:5432/saas_escolar')
    row = await conn.fetchrow("SELECT data_type FROM information_schema.columns WHERE table_name = 'turmas' AND column_name = 'ano_letivo';")
    print(f"ano_letivo data_type: {row['data_type'] if row else 'NOT FOUND'}")
    await conn.close()

if __name__ == '__main__':
    asyncio.run(main())