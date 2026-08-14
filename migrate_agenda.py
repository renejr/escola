import asyncio
import asyncpg

async def main():
    conn = await asyncpg.connect('postgresql://postgres:%40energy12%23@localhost:5432/saas_escolar')
    
    query = """
    CREATE TABLE IF NOT EXISTS eventos_agenda (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        escola_id UUID NOT NULL REFERENCES escolas(id),
        titulo VARCHAR(255) NOT NULL,
        descricao TEXT,
        data_inicio TIMESTAMP NOT NULL,
        data_fim TIMESTAMP NOT NULL,
        tipo VARCHAR(100),
        turma_id UUID REFERENCES turmas(id) ON DELETE CASCADE,
        criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """
    try:
        await conn.execute(query)
        print("Tabela eventos_agenda criada com sucesso.")
    except Exception as e:
        print(f"Erro ao criar tabela: {e}")
    finally:
        await conn.close()

if __name__ == '__main__':
    asyncio.run(main())