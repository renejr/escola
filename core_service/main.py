from fastapi import FastAPI, HTTPException, Depends, Header, Request
from pydantic import BaseModel
import uvicorn
from dotenv import load_dotenv
import os
import httpx
import asyncio
import jwt
import asyncpg
import json
from pgvector.asyncpg import register_vector
from typing import Optional

load_dotenv()

app = FastAPI(title="Core Escolar - SaaS Escolar")

from router_responsaveis import router as responsaveis_router
from router_alunos import router as alunos_router
from router_materias import router as materias_router
from router_grade import router as grade_router
from router_professores import router as professores_router
from router_turmas import router as turmas_router
from router_agenda import router as agenda_router
from router_notificacoes import router as notificacoes_router
from router_usuarios import router as usuarios_router
from router_whatsapp import router as whatsapp_router
from router_escolas import router as escolas_router
from router_superadmin import router as superadmin_router

app.include_router(responsaveis_router)
app.include_router(alunos_router)
app.include_router(materias_router)
app.include_router(grade_router)
app.include_router(professores_router)
app.include_router(turmas_router)
app.include_router(agenda_router)
app.include_router(notificacoes_router)
app.include_router(usuarios_router)
app.include_router(whatsapp_router)
app.include_router(escolas_router)
app.include_router(superadmin_router)

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
LLM_TIMEOUT = int(os.getenv("LLM_TIMEOUT", "30"))
MAX_CONCURRENCY = int(os.getenv("MAX_CONCURRENCY", "2"))
DATABASE_URL = os.getenv("DATABASE_URL")
JWT_SECRET = os.getenv("JWT_SECRET")
ALGORITHM = "HS256"

# Controle de concorrência para GPUs com VRAM limitada (4GB)
llm_semaphore = asyncio.Semaphore(MAX_CONCURRENCY)

class NotaCreate(BaseModel):
    aluno_id: str
    disciplina: str
    valor_nota: float
    bimestre: int

class FrequenciaItem(BaseModel):
    aluno_id: str
    status: str

class FrequenciaCreate(BaseModel):
    turma_id: str
    data: str
    frequencias: list[FrequenciaItem]

class MemoriaIA(BaseModel):
    texto: str
    tipo_contexto: str
    referencia_id: Optional[str] = None

class PerguntaIA(BaseModel):
    pergunta: str

from deps import get_db, get_tenant_context, require_role, registrar_auditoria

# Controle de concorrência para GPUs com VRAM limitada (4GB)

@app.post("/core/notas")
async def criar_nota(
    nota: NotaCreate, 
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario', 'professor'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    
    query = """
        INSERT INTO notas (aluno_id, escola_id, disciplina, valor_nota, bimestre) 
        VALUES ($1::uuid, $2::uuid, $3, $4, $5) 
        RETURNING id
    """
    try:
        nota_id = await conn.fetchval(query, nota.aluno_id, escola_id, nota.disciplina, nota.valor_nota, nota.bimestre)
        return {
            "id": str(nota_id), 
            "aluno_id": nota.aluno_id, 
            "disciplina": nota.disciplina, 
            "valor_nota": nota.valor_nota, 
            "bimestre": nota.bimestre, 
            "escola_id": escola_id
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/core/notas/{aluno_id}")
async def listar_notas(
    aluno_id: str,
    tenant: dict = Depends(get_tenant_context),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    
    query = """
        SELECT id, disciplina, valor_nota, bimestre 
        FROM notas 
        WHERE escola_id = $1::uuid AND aluno_id = $2::uuid 
        ORDER BY bimestre ASC
    """
    rows = await conn.fetch(query, escola_id, aluno_id)
    
    return [
        {
            "id": str(row["id"]), 
            "disciplina": row["disciplina"], 
            "valor_nota": float(row["valor_nota"]), 
            "bimestre": row["bimestre"]
        } 
        for row in rows
    ]

@app.post("/core/frequencia")
async def registrar_frequencia(
    freq_data: FrequenciaCreate,
    request: Request,
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario', 'professor'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    usuario_id = tenant.get("sub")
    
    query = """
        INSERT INTO frequencia (aluno_id, turma_id, escola_id, data, status) 
        VALUES ($1::uuid, $2::uuid, $3::uuid, $4::date, $5)
        ON CONFLICT (aluno_id, turma_id, data) 
        DO UPDATE SET status = EXCLUDED.status
    """
    
    try:
        # Usando transação para inserir/atualizar todos os alunos
        async with conn.transaction():
            for freq in freq_data.frequencias:
                await conn.execute(
                    query, 
                    freq.aluno_id, 
                    freq_data.turma_id, 
                    escola_id, 
                    freq_data.data, 
                    freq.status
                )
                
        # Auditoria
        ip = request.client.host if request.client else "unknown"
        await registrar_auditoria(
            conn, 
            usuario_id=usuario_id, 
            acao='REGISTER_FREQUENCIA', 
            detalhes={"turma_id": freq_data.turma_id, "data": freq_data.data, "total_registros": len(freq_data.frequencias)}, 
            ip_address=ip
        )
                
        return {"message": "Frequência registrada com sucesso"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/core/frequencia/{turma_id}")
async def obter_frequencia(
    turma_id: str,
    data: Optional[str] = None,
    tenant: dict = Depends(require_role(['admin', 'diretor', 'secretario', 'professor'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    
    if data:
        query = """
            SELECT aluno_id, status 
            FROM frequencia 
            WHERE escola_id = $1::uuid AND turma_id = $2::uuid AND data = $3::date
        """
        rows = await conn.fetch(query, escola_id, turma_id, data)
    else:
        query = """
            SELECT aluno_id, data, status 
            FROM frequencia 
            WHERE escola_id = $1::uuid AND turma_id = $2::uuid
            ORDER BY data DESC
        """
        rows = await conn.fetch(query, escola_id, turma_id)
        
    return [dict(row) for row in rows]

@app.get("/core/dashboard")
async def obter_dashboard(
    tenant: dict = Depends(get_tenant_context),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant.get("escola_id")
    
    try:
        total_turmas = await conn.fetchval("SELECT COUNT(id) FROM turmas WHERE escola_id = $1::uuid", escola_id)
        total_alunos = await conn.fetchval("SELECT COUNT(id) FROM alunos WHERE escola_id = $1::uuid", escola_id)
        
        return {
            "total_turmas": total_turmas or 0,
            "total_alunos": total_alunos or 0
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/core/health")
def health_check():
    return {
        "status": "ok", 
        "service": "Core Escolar", 
        "llm_url": OLLAMA_URL,
        "llm_timeout": LLM_TIMEOUT,
        "max_concurrency": MAX_CONCURRENCY
    }

@app.get("/core/auditoria")
async def listar_auditoria(
    limite: int = 50,
    offset: int = 0,
    tenant: dict = Depends(require_role(['admin'])),
    conn: asyncpg.Connection = Depends(get_db)
):
    query = """
        SELECT id, usuario_id, acao, detalhes, ip_address, criado_em 
        FROM audit_logs 
        ORDER BY criado_em DESC 
        LIMIT $1 OFFSET $2
    """
    try:
        rows = await conn.fetch(query, limite, offset)
        return [
            {
                "id": str(row["id"]),
                "usuario_id": str(row["usuario_id"]) if row["usuario_id"] else None,
                "acao": row["acao"],
                "detalhes": json.loads(row["detalhes"]) if isinstance(row["detalhes"], str) else row["detalhes"],
                "ip_address": row["ip_address"],
                "criado_em": row["criado_em"].isoformat() if row["criado_em"] else None
            } 
            for row in rows
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao buscar auditoria: {str(e)}")

@app.post("/core/ia/memoria")
async def alimentar_memoria(
    memoria: MemoriaIA,
    tenant: dict = Depends(get_tenant_context),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    
    # 1. Obter embeddings do Ollama (nomic-embed-text)
    async with llm_semaphore:
        async with httpx.AsyncClient(timeout=LLM_TIMEOUT) as client:
            try:
                response = await client.post(
                    f"{OLLAMA_URL}/api/embeddings",
                    json={"model": "nomic-embed-text", "prompt": memoria.texto}
                )
                response.raise_for_status()
                embedding = response.json().get("embedding")
            except httpx.ReadTimeout:
                raise HTTPException(status_code=504, detail="Timeout ao gerar embeddings no Ollama.")
            except Exception as e:
                raise HTTPException(status_code=500, detail=f"Erro no Ollama: {str(e)}")

    if not embedding:
        raise HTTPException(status_code=500, detail="Ollama não retornou embeddings.")

    # 2. Salvar no PostgreSQL garantindo o isolamento do tenant
    query = """
        INSERT INTO memoria_ia (escola_id, conteudo_texto, tipo_contexto, referencia_id, embedding)
        VALUES ($1::uuid, $2, $3, $4, $5) RETURNING id
    """
    try:
        # A biblioteca pgvector trata o array python nativamente após o register_vector
        memoria_id = await conn.fetchval(
            query, escola_id, memoria.texto, memoria.tipo_contexto, memoria.referencia_id, embedding
        )
        return {"message": "Memória salva com sucesso", "id": str(memoria_id), "escola_id": escola_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao salvar no banco: {str(e)}")

@app.post("/core/ia/perguntar")
async def perguntar_ia(
    pergunta_req: PerguntaIA,
    tenant: dict = Depends(get_tenant_context),
    conn: asyncpg.Connection = Depends(get_db)
):
    escola_id = tenant["escola_id"]
    pergunta = pergunta_req.pergunta

    # 1. Gerar embedding da pergunta
    async with llm_semaphore:
        async with httpx.AsyncClient(timeout=LLM_TIMEOUT) as client:
            try:
                response = await client.post(
                    f"{OLLAMA_URL}/api/embeddings",
                    json={"model": "nomic-embed-text", "prompt": pergunta}
                )
                response.raise_for_status()
                embedding_pergunta = response.json().get("embedding")
            except Exception as e:
                raise HTTPException(status_code=500, detail=f"Erro ao gerar embedding da pergunta: {str(e)}")

    if not embedding_pergunta:
        raise HTTPException(status_code=500, detail="Falha ao obter embedding da pergunta.")

    # 2. Busca por Similaridade no PostgreSQL (limitado a 3 e blindado pelo tenant)
    # Utilizamos <=> que é a distância do cosseno para o pgvector
    query = """
        SELECT conteudo_texto, tipo_contexto 
        FROM memoria_ia 
        WHERE escola_id = $1::uuid
        ORDER BY embedding <=> $2 
        LIMIT 3
    """
    try:
        rows = await conn.fetch(query, escola_id, embedding_pergunta)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao consultar vetor no banco: {str(e)}")

    if not rows:
        return {"resposta": "Não encontrei informações no banco de dados da escola para responder a isso."}

    # 3. Concatenar o contexto
    contexto_recuperado = "\n".join([f"[{r['tipo_contexto'].upper()}] {r['conteudo_texto']}" for r in rows])
    
    prompt_final = f"Você é um assistente de gestão escolar inteligente e profissional. O seu objetivo é ajudar professores e diretores respondendo perguntas. REGRAS ABSOLUTAS: 1) Responda SEMPRE em Português do Brasil. 2) Baseie-se EXCLUSIVAMENTE no seguinte contexto recuperado da escola: {contexto_recuperado}. 3) Se a resposta não estiver no contexto, responda EXATAMENTE: 'Desculpe, não encontrei essa informação nos registros da escola.' PERGUNTA DO USUÁRIO: {pergunta}"

    # 4. Enviar o prompt com contexto para o LLM de Inferência (usando phi3 ou qwen2.5)
    async with llm_semaphore:
        async with httpx.AsyncClient(timeout=LLM_TIMEOUT * 2) as client:  # Dobro do tempo pois a inferência é mais pesada
            try:
                response = await client.post(
                    f"{OLLAMA_URL}/api/generate",
                    json={
                        "model": "phi3", # Você pode mudar para qwen2.5 depois se desejar
                        "prompt": prompt_final, 
                        "stream": False
                    }
                )
                response.raise_for_status()
                resultado = response.json()
                return {
                    "resposta": resultado.get("response", ""),
                    "contexto_utilizado": contexto_recuperado
                }
            except Exception as e:
                raise HTTPException(status_code=500, detail=f"Erro na inferência da IA: {str(e)}")

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8082, reload=True)
