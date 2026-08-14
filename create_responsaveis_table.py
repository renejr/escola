import asyncio
import asyncpg
import os
from dotenv import load_dotenv

load_dotenv(dotenv_path="d:/escola/core_service/.env")

DATABASE_URL = os.getenv("DATABASE_URL")

async def create_table():
    conn = await asyncpg.connect(DATABASE_URL)
    
    query = """
    CREATE TABLE IF NOT EXISTS responsaveis (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        escola_id UUID NOT NULL REFERENCES escolas(id) ON DELETE CASCADE,
        nome VARCHAR NOT NULL,
        cpf VARCHAR NOT NULL,
        email VARCHAR NOT NULL,
        celular VARCHAR NOT NULL,
        emergencia_nome VARCHAR,
        emergencia_telefone VARCHAR,
        cep VARCHAR,
        logradouro VARCHAR,
        numero VARCHAR,
        complemento VARCHAR,
        bairro VARCHAR,
        cidade VARCHAR,
        estado VARCHAR,
        foto_url VARCHAR,
        comprovante_url VARCHAR,
        ativo BOOLEAN DEFAULT TRUE,
        UNIQUE(cpf, escola_id),
        UNIQUE(email, escola_id)
    );
    """
    
    try:
        await conn.execute(query)
        print("Tabela 'responsaveis' criada com sucesso!")
    except Exception as e:
        print(f"Erro ao criar tabela: {e}")
    finally:
        await conn.close()

if __name__ == "__main__":
    asyncio.run(create_table())
