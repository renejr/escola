import asyncio
import asyncpg
import os

DATABASE_URL = "postgresql://postgres:%40energy12%23@localhost:5432/saas_escolar"

async def create_notas_table():
    conn = await asyncpg.connect(DATABASE_URL)
    
    try:
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS notas ( 
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(), 
                escola_id UUID REFERENCES escolas(id), 
                aluno_id UUID REFERENCES alunos(id) ON DELETE CASCADE, 
                disciplina VARCHAR(100) NOT NULL, 
                valor_nota NUMERIC(5,2) NOT NULL, 
                bimestre INTEGER NOT NULL, 
                criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP 
            );
        """)
        print("Tabela 'notas' verificada/criada com sucesso!")
    except asyncpg.exceptions.UndefinedFunctionError:
        # Se não tiver gen_random_uuid, tenta uuid_generate_v4
         await conn.execute("""
            CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
            CREATE TABLE IF NOT EXISTS notas ( 
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), 
                escola_id UUID REFERENCES escolas(id), 
                aluno_id UUID REFERENCES alunos(id) ON DELETE CASCADE, 
                disciplina VARCHAR(100) NOT NULL, 
                valor_nota NUMERIC(5,2) NOT NULL, 
                bimestre INTEGER NOT NULL, 
                criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP 
            );
        """)
         print("Tabela 'notas' verificada/criada com sucesso (uuid-ossp)!")
    except Exception as e:
        print(f"Erro: {e}")
        try:
            await conn.execute("""
                CREATE TABLE IF NOT EXISTS notas ( 
                    id UUID PRIMARY KEY DEFAULT gen_random_uuid(), 
                    escola_id UUID, 
                    aluno_id UUID, 
                    disciplina VARCHAR(100) NOT NULL, 
                    valor_nota NUMERIC(5,2) NOT NULL, 
                    bimestre INTEGER NOT NULL, 
                    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP 
                );
            """)
        except Exception as e2:
            pass
    finally:
        await conn.close()

if __name__ == "__main__":
    asyncio.run(create_notas_table())