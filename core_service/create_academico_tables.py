import asyncio
import asyncpg
import os

DATABASE_URL = "postgresql://postgres:%40energy12%23@localhost:5432/saas_escolar"

async def main():
    conn = await asyncpg.connect(DATABASE_URL)
    
    # Criar tabela materias
    await conn.execute('''
        CREATE TABLE IF NOT EXISTS materias (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            escola_id UUID NOT NULL,
            nome VARCHAR(255) NOT NULL,
            area_conhecimento VARCHAR(255),
            ativo BOOLEAN DEFAULT TRUE,
            criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        )
    ''')

    # Criar tabela grade_curricular
    await conn.execute('''
        CREATE TABLE IF NOT EXISTS grade_curricular (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            turma_id UUID NOT NULL REFERENCES turmas(id) ON DELETE CASCADE,
            materia_id UUID NOT NULL REFERENCES materias(id) ON DELETE CASCADE,
            professor_id UUID NOT NULL,
            carga_horaria INTEGER NOT NULL,
            ativo BOOLEAN DEFAULT TRUE,
            criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            escola_id UUID NOT NULL
        )
    ''')
    
    print("Tabelas criadas com sucesso!")
    await conn.close()

if __name__ == "__main__":
    asyncio.run(main())