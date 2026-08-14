import asyncio
import asyncpg
import os

DATABASE_URL = "postgresql://postgres:%40energy12%23@localhost:5432/saas_escolar"

async def fix_vector_dimensions():
    print("Conectando ao banco de dados...")
    conn = await asyncpg.connect(DATABASE_URL)
    
    print("Ajustando a dimensão do vetor na tabela memoria_ia para 768 (padrão do nomic-embed-text)...")
    try:
        await conn.execute("""
            ALTER TABLE memoria_ia 
            ALTER COLUMN embedding TYPE vector(768);
        """)
        print("✅ Tabela atualizada com sucesso!")
    except Exception as e:
        print(f"Erro: {e}")
    finally:
        await conn.close()

if __name__ == "__main__":
    asyncio.run(fix_vector_dimensions())