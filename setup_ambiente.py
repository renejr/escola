import os
import subprocess
import sys
from pathlib import Path

def run_cmd(cmd, cwd=None):
    print(f"Executando: {cmd} em {cwd or '.'}")
    subprocess.run(cmd, shell=True, cwd=cwd, check=True)

def create_file(path, content):
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# Credenciais e configurações (segurança: armazenadas apenas no .env)
DB_URL = "postgresql://admin:@energy12#@localhost:5432/saas_escolar"

services = {
    "gateway_service": {
        "deps": "fastapi uvicorn httpx python-dotenv",
        "env": "",
        "main": """from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse
import httpx
import uvicorn

app = FastAPI(title="API Gateway - SaaS Escolar")

AUTH_SERVICE_URL = "http://localhost:8001"
CORE_SERVICE_URL = "http://localhost:8002"

@app.api_route("/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"])
async def gateway(request: Request, path: str):
    if path.startswith("auth"):
        target_url = f"{AUTH_SERVICE_URL}/{path}"
    elif path.startswith("core"):
        target_url = f"{CORE_SERVICE_URL}/{path}"
    else:
        return JSONResponse(status_code=404, content={"message": "Rota não encontrada no Gateway"})
    
    headers = dict(request.headers)
    headers.pop("host", None)
    
    async with httpx.AsyncClient() as client:
        try:
            body = await request.body()
            response = await client.request(
                method=request.method,
                url=target_url,
                headers=headers,
                content=body
            )
            
            resp_headers = dict(response.headers)
            resp_headers.pop("content-length", None)
            resp_headers.pop("content-encoding", None)
            
            return Response(
                content=response.content, 
                status_code=response.status_code, 
                headers=resp_headers,
                media_type=response.headers.get("content-type")
            )
        except httpx.RequestError as exc:
            return JSONResponse(status_code=503, content={"message": f"Serviço indisponível: {exc}"})

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
"""
    },
    "auth_service": {
        "deps": "fastapi uvicorn pydantic pydantic-settings python-dotenv pyjwt passlib[bcrypt]",
        "env": f"DATABASE_URL={DB_URL}\nJWT_SECRET=super_secret_jwt_key_aqui\n",
        "main": """from fastapi import FastAPI
import uvicorn
from dotenv import load_dotenv
import os

load_dotenv()

app = FastAPI(title="Auth Service - SaaS Escolar")

@app.get("/auth/health")
def health_check():
    return {"status": "ok", "service": "Auth Service"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
"""
    },
    "core_service": {
        "deps": "fastapi uvicorn pydantic pydantic-settings psycopg2-binary asyncpg python-dotenv httpx",
        "env": f"DATABASE_URL={DB_URL}\nOLLAMA_URL=http://localhost:11434\nLLM_TIMEOUT=30\nMAX_CONCURRENCY=2\n",
        "main": """from fastapi import FastAPI, HTTPException
import uvicorn
from dotenv import load_dotenv
import os
import httpx
import asyncio

load_dotenv()

app = FastAPI(title="Core Escolar - SaaS Escolar")

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
LLM_TIMEOUT = int(os.getenv("LLM_TIMEOUT", "30"))
MAX_CONCURRENCY = int(os.getenv("MAX_CONCURRENCY", "2"))

# Controle de concorrência para GPUs com VRAM limitada (4GB)
llm_semaphore = asyncio.Semaphore(MAX_CONCURRENCY)

@app.get("/core/health")
def health_check():
    return {
        "status": "ok", 
        "service": "Core Escolar", 
        "llm_url": OLLAMA_URL,
        "llm_timeout": LLM_TIMEOUT,
        "max_concurrency": MAX_CONCURRENCY
    }

@app.post("/core/ai/generate")
async def generate_ai_response(prompt: str):
    async with llm_semaphore:
        async with httpx.AsyncClient(timeout=LLM_TIMEOUT) as client:
            try:
                response = await client.post(
                    f"{OLLAMA_URL}/api/generate",
                    json={"model": "llama3", "prompt": prompt, "stream": False}
                )
                response.raise_for_status()
                return response.json()
            except httpx.ReadTimeout:
                raise HTTPException(status_code=504, detail="Timeout no processamento da IA.")
            except Exception as e:
                raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8002, reload=True)
"""
    }
}

def main():
    base_dir = Path.cwd()
    print(f"Iniciando a criação da arquitetura em: {base_dir}")
    
    for svc, data in services.items():
        print(f"\n--- Configurando {svc} ---")
        svc_dir = base_dir / svc
        svc_dir.mkdir(exist_ok=True)
        
        create_file(svc_dir / "requirements.txt", data["deps"].replace(" ", "\n"))
        create_file(svc_dir / ".env", data["env"])
        create_file(svc_dir / "main.py", data["main"])
        
        print("Criando ambiente virtual...")
        run_cmd(f"{sys.executable} -m venv venv", cwd=svc_dir)
        
        pip_exe = svc_dir / "venv" / "Scripts" / "pip" if os.name == 'nt' else svc_dir / "venv" / "bin" / "pip"
        print("Instalando dependências...")
        run_cmd(f"{pip_exe} install -r requirements.txt", cwd=svc_dir)
        
    print("\n[Missão Cumprida] Arquitetura configurada com sucesso!")

if __name__ == "__main__":
    main()
