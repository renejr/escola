@echo off
echo ===================================================
echo Encerrando instancias antigas dos servicos...
echo ===================================================

echo 1. Fechando janelas de terminal ativas...
taskkill /FI "WINDOWTITLE eq Auth Service*" /T /F >nul 2>&1
taskkill /FI "WINDOWTITLE eq Core Service*" /T /F >nul 2>&1
taskkill /FI "WINDOWTITLE eq Gateway Service*" /T /F >nul 2>&1

echo 2. Liberando portas presas (8081, 8082, 8080)...
for %%p in (8081 8082 8080) do (
    for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":%%p "') do (
        echo - Processo orfao encontrado [PID %%a] na porta %%p. Encerrando...
        taskkill /F /T /PID %%a >nul 2>&1
    )
)

echo.
echo ===================================================
echo Iniciando Microservicos - SaaS Escolar...
echo ===================================================

echo Iniciando Auth Service (Porta 8081)...
start "Auth Service" cmd /k "cd auth_service && call venv\Scripts\activate && uvicorn main:app --host 0.0.0.0 --port 8081 --reload"

echo Iniciando Core Escolar (Porta 8082)...
start "Core Service" cmd /k "cd core_service && call venv\Scripts\activate && uvicorn main:app --host 0.0.0.0 --port 8082 --reload"

echo Iniciando API Gateway (Porta 8080)...
start "Gateway Service" cmd /k "cd gateway_service && call venv\Scripts\activate && uvicorn main:app --host 0.0.0.0 --port 8080 --reload"

echo.
echo Todos os servicos foram reiniciados em novas janelas e de forma limpa!
pause
