import asyncio
import asyncpg
import bcrypt
import os

DATABASE_URL = "postgresql://postgres:%40energy12%23@localhost:5432/saas_escolar"

async def fix_password():
    print("Gerando novo hash para a senha '123456'...")
    # Gera um hash real válido com a biblioteca atual
    salt = bcrypt.gensalt()
    senha_hash = bcrypt.hashpw(b"123456", salt).decode('utf-8')
    print(f"Novo Hash gerado: {senha_hash}")
    
    print("Conectando ao banco de dados...")
    conn = await asyncpg.connect(DATABASE_URL)
    
    print("Atualizando o hash do usuário admin@escolaalpha.com.br...")
    await conn.execute(
        "UPDATE usuarios SET senha_hash = $1 WHERE email = $2",
        senha_hash,
        "admin@escolaalpha.com.br"
    )
    
    print("✅ Hash atualizado com sucesso no PostgreSQL!")
    await conn.close()

if __name__ == "__main__":
    asyncio.run(fix_password())