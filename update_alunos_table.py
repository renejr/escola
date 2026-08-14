import asyncio
import asyncpg
import os
from dotenv import load_dotenv

load_dotenv(dotenv_path="d:/escola/core_service/.env")
DATABASE_URL = os.getenv("DATABASE_URL")

async def update_tables():
    conn = await asyncpg.connect(DATABASE_URL)
    
    # Adicionando colunas novas na tabela alunos, caso não existam
    # Renomeando matricula para matricula_ra ou mantendo matricula e adicionando data_nascimento
    queries = [
        "ALTER TABLE alunos ADD COLUMN IF NOT EXISTS data_nascimento DATE DEFAULT '2000-01-01';",
        "ALTER TABLE alunos ADD COLUMN IF NOT EXISTS cpf VARCHAR;",
        "ALTER TABLE alunos ADD COLUMN IF NOT EXISTS foto_url VARCHAR;",
        "ALTER TABLE alunos ADD COLUMN IF NOT EXISTS ativo BOOLEAN DEFAULT TRUE;",
        "ALTER TABLE alunos RENAME COLUMN matricula TO matricula_ra;",
        # Adicionar constraint UNIQUE em matricula_ra e escola_id se não existir
        "ALTER TABLE alunos DROP CONSTRAINT IF EXISTS alunos_matricula_ra_escola_id_key;",
        "ALTER TABLE alunos ADD CONSTRAINT alunos_matricula_ra_escola_id_key UNIQUE (matricula_ra, escola_id);",
        
        # Tabela aluno_responsavel
        """
        CREATE TABLE IF NOT EXISTS aluno_responsavel (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            aluno_id UUID NOT NULL REFERENCES alunos(id) ON DELETE CASCADE,
            responsavel_id UUID NOT NULL REFERENCES responsaveis(id) ON DELETE CASCADE,
            parentesco VARCHAR NOT NULL,
            financeiro BOOLEAN DEFAULT FALSE,
            UNIQUE(aluno_id, responsavel_id)
        );
        """
    ]
    
    try:
        for q in queries:
            try:
                await conn.execute(q)
                print(f"Executado: {q}")
            except Exception as inner_e:
                print(f"Erro ignorado ou falha na query {q}: {inner_e}")
        print("Tabelas atualizadas com sucesso!")
    except Exception as e:
        print(f"Erro geral: {e}")
    finally:
        await conn.close()

if __name__ == "__main__":
    asyncio.run(update_tables())
