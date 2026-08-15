import asyncio
import asyncpg
import os
from dotenv import load_dotenv

load_dotenv()

async def main():
    conn = await asyncpg.connect(os.getenv("DATABASE_URL"))
    
    # Check if escolas table exists
    exists = await conn.fetchval("""
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE  table_schema = 'public'
            AND    table_name   = 'escolas'
        );
    """)
    
    if not exists:
        print("Creating escolas table...")
        await conn.execute("""
            CREATE TABLE escolas (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                razao_social VARCHAR(255) NOT NULL,
                cnpj VARCHAR(20) UNIQUE NOT NULL,
                nome_fantasia VARCHAR(255) NOT NULL,
                logo_url VARCHAR(500),
                cor_primaria VARCHAR(10),
                telefone VARCHAR(20),
                email_contato VARCHAR(255),
                ativo BOOLEAN DEFAULT TRUE,
                criado_em TIMESTAMP DEFAULT NOW()
            )
        """)
        print("escolas table created.")
        
        # We also need to insert a default one for the current user to be linked if not linked
        # Actually, let's see if there are any users and what their escola_id is
        users = await conn.fetch("SELECT id, escola_id FROM usuarios LIMIT 1")
        if users and users[0]['escola_id']:
            print(f"User has escola_id: {users[0]['escola_id']}")
            # Insert this escola_id into escolas table
            try:
                await conn.execute("""
                    INSERT INTO escolas (id, razao_social, cnpj, nome_fantasia)
                    VALUES ($1, 'Escola Alpha LTDA', '00.000.000/0001-00', 'Escola Alpha')
                """, users[0]['escola_id'])
                print("Inserted default escola.")
            except Exception as e:
                print(f"Error inserting default escola: {e}")
    else:
        print("escolas table already exists. Checking columns...")
        # Add columns if missing
        cols = ["razao_social", "cnpj", "nome_fantasia", "logo_url", "cor_primaria", "telefone", "email_contato", "ativo"]
        for col in cols:
            try:
                await conn.execute(f"ALTER TABLE escolas ADD COLUMN {col} VARCHAR(255)")
                print(f"Added column {col}")
            except Exception as e:
                pass # Probably already exists
                
    await conn.close()

asyncio.run(main())
