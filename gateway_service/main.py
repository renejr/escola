from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import httpx
import uvicorn
import os

app = FastAPI(title="API Gateway - SaaS Escolar")

# Configuração essencial de CORS para permitir requisições do Flutter Web (Navegador)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Em produção, mude para o domínio real do seu frontend
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

AUTH_SERVICE_URL = os.getenv("AUTH_SERVICE_URL", "http://localhost:8081")
CORE_SERVICE_URL = os.getenv("CORE_SERVICE_URL", "http://localhost:8082")

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
    
    async with httpx.AsyncClient(timeout=120.0) as client:
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
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)
