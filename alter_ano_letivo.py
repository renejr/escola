import asyncio
import asyncpg

async def main():
    conn = await asyncpg.connect('postgresql://postgres:%40energy12%23@localhost:5432/saas_escolar')
    try:
        await conn.execute("ALTER TABLE turmas ALTER COLUMN ano_letivo TYPE VARCHAR(20);")
        print("Coluna ano_letivo alterada para VARCHAR(20).")
    except Exception as e:
        print(f"Erro: {e}")
    finally:
        await conn.close()

if __name__ == '__main__':
    asyncio.run(main())