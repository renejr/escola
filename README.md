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

- Arquitetura White-label / Multitenant (Escolas isoladas e blindadas no banco de dados com `escola_id`).
- Provisionamento Atômico de Tenants (Criação simultânea da Instituição e seu Usuário Administrador inicial).
- Painel Super Admin ("Sala Cofre") para gerenciamento global de Escolas/Tenants e KPIs.
- Autenticação e Controle de Acesso (RBAC estrito: Super Admin, Admin, Diretor, Secretário, Professor).
- Gestão de Alunos e Responsáveis (Relacionamento N:N com Autocomplete de busca).
- Gestão de Professores (CRUD completo com Toggle de Ativação/Inativação).
- Gestão de Turmas (Interface em Abas: Info, Alunos, Grade Curricular).
- Catálogo de Matérias e Grade Curricular.
- Agenda Escolar (Calendário interativo, Eventos Globais e por Turma).
- Central de Notificações (Sino com Badge e avisos automáticos gerados pela Agenda).
- Controle de Usuários (Gerenciamento mestre de perfis e acessos do sistema).
- Mensageria Global e Alertas (Disparo de E-mails via SMTP e Integração WhatsApp via Evolution API).
- Trilha de Auditoria com suporte Multitenant (Logs rastreados por Tenant/Escola).
- Diário de Classe Web/Desktop (Otimizado com Optimistic UI e Debounce para digitação ultra-rápida).
- Gestão de Anos e Períodos Letivos (Arquitetura de "Ano Ativo" exclusivo).
- Módulo Financeiro Integrado (Geração de Carnês em Lote, rateio automático e links de Checkout Pro via Mercado Pago).
- Motor de Conciliação Ativa Financeira (Robô Assíncrono com Janela Contínua de 5 Dias e auto-arquivamento).
- Régua de Cobrança Automatizada (Robô de Notificações D-5 e D-0 com envio de E-mails HTML contendo link de pagamento).
- Frontend com design moderno (Material 3 e Layouts isolados: MainLayout vs SuperAdminLayout).
- Suite de Testes E2E (Automação completa do fluxo do SuperAdmin, CRUDs e blindagem de segurança por Roles).
