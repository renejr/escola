# Instruções de Inicialização Local - SaaS Escolar

Este documento detalha o passo a passo para subir toda a infraestrutura do projeto localmente no Windows.

## Pré-requisitos
- Python 3.x instalado e adicionado ao PATH.
- Flutter SDK instalado e configurado.
- PostgreSQL rodando localmente (com o banco `saas_escolar` e a extensão `pgvector`).
- Ollama instalado e rodando com os modelos `nomic-embed-text` e `phi3` baixados.

---

## Passo 1: Iniciar os Microserviços (Backend)

Nosso backend é dividido em três serviços que rodam em portas separadas (já configuradas para evitar conflitos com outros serviços na porta 8000/5000).
- **Gateway Service**: Porta 8080
- **Auth Service**: Porta 8081
- **Core Service**: Porta 8082

Você pode iniciar todos de uma vez usando o arquivo `.bat` ou iniciar um por um manualmente:

### Opção A: Usando o Script Automático (Recomendado)
Basta dar um duplo clique no arquivo `run_services.bat` localizado na raiz do projeto (`d:\escola`). Ele abrirá três janelas do prompt de comando, ativará os ambientes virtuais e rodará o Uvicorn automaticamente.

### Opção B: Iniciando Manualmente via Terminal
Abra o terminal (PowerShell ou CMD) na raiz do projeto (`d:\escola`) e siga os passos abaixo em três abas/janelas diferentes:

**Janela 1 (Gateway Service):**
```cmd
cd gateway_service
venv\Scripts\activate
uvicorn main:app --host 0.0.0.0 --port 8080 --reload
```

**Janela 2 (Auth Service):**
```cmd
cd auth_service
venv\Scripts\activate
uvicorn main:app --host 0.0.0.0 --port 8081 --reload
```

**Janela 3 (Core Service):**
```cmd
cd core_service
venv\Scripts\activate
uvicorn main:app --host 0.0.0.0 --port 8082 --reload
```

*(Nota: Para desativar o ambiente virtual em qualquer momento, basta digitar `deactivate`).*

---

## Passo 2: Iniciar o Aplicativo (Frontend - Flutter)

Com o backend rodando, abra uma nova janela de terminal (PowerShell/CMD) na raiz do projeto e siga os passos:

```cmd
cd app_escola
flutter pub get
flutter run
```

O Flutter perguntará em qual dispositivo você deseja rodar (Emulador Android, Edge/Chrome para Web, ou Windows Desktop). Selecione a opção desejada. 
- *Atenção:* O `api_client.dart` já está configurado para resolver a URL correta dinamicamente (`127.0.0.1` para Web/Desktop e `10.0.2.2` para Android) apontando para o Gateway na porta `8080`.

---

## Credenciais de Teste Locais
- **E-mail:** `admin@escolaalpha.com.br`
- **Senha:** `123456`

---

## Serviços de IA (Ollama)
Certifique-se de que o ícone do Ollama está ativo na bandeja do sistema (perto do relógio do Windows). Ele opera na porta `11434` em background.
Caso precise baixar os modelos manualmente:
```cmd
ollama pull nomic-embed-text
ollama pull phi3
```
