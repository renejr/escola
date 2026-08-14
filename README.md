# SaaS Escolar

Sistema Multitenant de Gestão Escolar com backend em Python (FastAPI) e frontend em Flutter (Material 3).

## Estrutura do Projeto

- `core_service/`: Microserviço principal responsável pelo cadastro de escolas, usuários, matérias, turmas, notas e frequência.
- `auth_service/`: Microserviço responsável pela autenticação e autorização (JWT).
- `app_escola/`: Aplicativo Frontend desenvolvido em Flutter.
- `run_services.bat`: Script de inicialização dos serviços do backend localmente.

## Requisitos

- Python 3.10+
- PostgreSQL
- Flutter SDK 3.x+

## Configuração e Execução

1. Configure as variáveis de ambiente nos arquivos `.env` dos serviços.
2. Execute o script `run_services.bat` para iniciar o backend.
3. No diretório `app_escola/`, execute `flutter run` para rodar o aplicativo.

## Funcionalidades Principais

- Autenticação e Controle de Acesso (RBAC: Admin, Diretor, Secretário, Professor).
- Gestão de Alunos e Responsáveis (Relacionamento N:N).
- Catálogo de Matérias e Grade Curricular.
- Trilha de Auditoria (Logs).
