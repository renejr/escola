import asyncio
import asyncpg
import os
from dotenv import load_dotenv

load_dotenv('core_service/.env')

async def inject_superadmin():
    db_url = os.getenv("DATABASE_URL")
    print("Conectando ao banco de dados...")
    conn = await asyncpg.connect(db_url)

    try:
        # 1. Remover a restrição NOT NULL da coluna escola_id na tabela usuarios
        print("Ajustando restrição da coluna escola_id para permitir NULL (Superadmin)...")
        await conn.execute("ALTER TABLE usuarios ALTER COLUMN escola_id DROP NOT NULL;")

        # 2. Hash pre-gerado pelo bcrypt
        senha_hash = "$2b$12$EvJzA200vTyXvGj3QVflaewcukzL2dvWUUmEpeVYpjWLhBToff2c2"

        # 3. Dados do Superadmin
        nome = "Rene Ballesteros Machado Junior"
        email = "renebmjr@gmail.com"
        celular = "11991782694"
        papel = "superadmin"

        # 4. Inserir ou Atualizar o usuário
        existing = await conn.fetchval("SELECT id FROM usuarios WHERE email = $1", email)
        
        if existing:
            await conn.execute(
                """
                UPDATE usuarios
                SET nome = $1, senha_hash = $2, celular = $3, papel = $4, escola_id = NULL, ativo = true
                WHERE email = $5
                """,
                nome, senha_hash, celular, papel, email
            )
            print(f"Superadmin {email} atualizado com sucesso!")
        else:
            await conn.execute(
                """
                INSERT INTO usuarios (nome, email, senha_hash, papel, celular, escola_id, ativo)
                VALUES ($1, $2, $3, $4, $5, NULL, true)
                """,
                nome, email, senha_hash, papel, celular
            )
            print(f"Superadmin {email} criado com sucesso!")

    except Exception as e:
        print(f"Erro durante a injeção: {e}")
    finally:
        await conn.close()
        print("Conexão encerrada.")

if __name__ == "__main__":
    asyncio.run(inject_superadmin())