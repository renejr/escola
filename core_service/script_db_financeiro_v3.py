import asyncio
import asyncpg
import os
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")

async def migrate_db():
    conn = await asyncpg.connect(DATABASE_URL)
    try:
        print("Iniciando migração da tabela contas_receber...")
        
        # Remover colunas obsoletas
        await conn.execute("ALTER TABLE contas_receber DROP COLUMN IF EXISTS tentativas_consulta")
        await conn.execute("ALTER TABLE contas_receber DROP COLUMN IF EXISTS proxima_consulta")
        
        # Adicionar novas colunas
        await conn.execute("ALTER TABLE contas_receber ADD COLUMN IF NOT EXISTS valor_bruto NUMERIC(10,2) DEFAULT 0")
        await conn.execute("ALTER TABLE contas_receber ADD COLUMN IF NOT EXISTS desconto NUMERIC(10,2) DEFAULT 0")
        await conn.execute("ALTER TABLE contas_receber ADD COLUMN IF NOT EXISTS motivo VARCHAR(50)")
        await conn.execute("ALTER TABLE contas_receber ADD COLUMN IF NOT EXISTS descricao TEXT")
        await conn.execute("ALTER TABLE contas_receber ADD COLUMN IF NOT EXISTS parcela_atual INT DEFAULT 1")
        await conn.execute("ALTER TABLE contas_receber ADD COLUMN IF NOT EXISTS total_parcelas INT DEFAULT 1")
        await conn.execute("ALTER TABLE contas_receber ADD COLUMN IF NOT EXISTS aviso_d5_enviado BOOLEAN DEFAULT FALSE")
        await conn.execute("ALTER TABLE contas_receber ADD COLUMN IF NOT EXISTS aviso_d0_enviado BOOLEAN DEFAULT FALSE")
        
        # Migrar valor atual para valor_bruto caso esteja 0
        await conn.execute("UPDATE contas_receber SET valor_bruto = valor WHERE valor_bruto = 0 OR valor_bruto IS NULL")
        
        print("Migração concluída com sucesso!")
    except Exception as e:
        print(f"Erro na migração: {e}")
    finally:
        await conn.close()

if __name__ == "__main__":
    asyncio.run(migrate_db())
