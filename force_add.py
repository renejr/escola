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
    try:
        await conn.execute("ALTER TABLE turmas ADD COLUMN ano_letivo VARCHAR(20);")
        print("Coluna adicionada.")
    except Exception as e:
        print(f"Erro: {e}")
    finally:
        await conn.close()

if __name__ == '__main__':
    asyncio.run(main())