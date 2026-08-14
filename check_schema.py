import asyncio
import asyncpg

async def main():
    conn = await asyncpg.connect('postgresql://postgres:%40energy12%23@localhost:5432/saas_escolar')
    rows = await conn.fetch("""
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = 'turmas';
    """)
    for row in rows:
        print(f"{row['column_name']}: {row['data_type']}")
    await conn.close()

if __name__ == '__main__':
    asyncio.run(main())