import asyncio
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from deps import get_db

scheduler_cobranca = AsyncIOScheduler()

def enviar_email(destinatario: str, assunto: str, corpo_html: str):
    try:
        msg = MIMEMultipart()
        msg['From'] = 'escola@mdxhq.com.br'
        msg['To'] = destinatario
        msg['Subject'] = assunto

        msg.attach(MIMEText(corpo_html, 'html'))

        s = smtplib.SMTP('smtp.titan.email', 587)
        s.starttls()
        s.login('escola@mdxhq.com.br', '$Energia12')
        s.send_message(msg)
        s.quit()
        return True
    except Exception as e:
        print(f"[ROBÔ COBRANÇA] Erro ao enviar e-mail para {destinatario}: {e}")
        return False

async def varrer_e_notificar():
    """
    Robô de Cobrança Ativa (Régua de Cobrança)
    Busca faturas D-5 e D-0 e envia notificação.
    """
    print("[ROBÔ COBRANÇA] Iniciando varredura diária de régua de cobrança...")
    
    async for conn in get_db():
        try:
            # 1. Varredura D-5 (Lembrete Amigável)
            query_d5 = """
                SELECT c.id, c.valor, c.data_vencimento, c.checkout_url, r.email, a.nome as aluno_nome
                FROM contas_receber c
                LEFT JOIN alunos a ON c.aluno_id = a.id
                LEFT JOIN responsaveis r ON c.responsavel_id = r.id OR a.responsavel_id = r.id
                WHERE c.status = 'Pendente' 
                  AND c.data_vencimento = (CURRENT_DATE + INTERVAL '5 days')
                  AND c.aviso_d5_enviado = FALSE
                  AND c.checkout_url IS NOT NULL
                  AND r.email IS NOT NULL
            """
            contas_d5 = await conn.fetch(query_d5)
            
            for conta in contas_d5:
                print(f"[ROBÔ COBRANÇA] Enviando D-5 para fatura {conta['id']}...")
                assunto = "Lembrete: Mensalidade Escolar próxima do vencimento"
                corpo = f"""
                <p>Olá,</p>
                <p>A mensalidade escolar do(a) aluno(a) <strong>{conta['aluno_nome']}</strong> no valor de <strong>R$ {conta['valor']:.2f}</strong> vence no dia <strong>{conta['data_vencimento'].strftime('%d/%m/%Y')}</strong>.</p>
                <p>Acesse o link abaixo para visualizar e pagar a fatura com comodidade:</p>
                <p><a href="{conta['checkout_url']}">Clique aqui para pagar</a></p>
                <p>Atenciosamente,<br>Secretaria Escolar</p>
                """
                
                # Descomentar para enviar e-mail real
                # if enviar_email(conta['email'], assunto, corpo):
                #     await conn.execute("UPDATE contas_receber SET aviso_d5_enviado = TRUE WHERE id = $1::uuid", conta['id'])
                
                # Simulação para MVP
                print(f"[ROBÔ COBRANÇA] [SIMULADO] E-mail D-5 enviado para {conta['email']}")
                await conn.execute("UPDATE contas_receber SET aviso_d5_enviado = TRUE WHERE id = $1::uuid", conta['id'])

            # 2. Varredura D-0 (Aviso de Vencimento)
            query_d0 = """
                SELECT c.id, c.valor, c.data_vencimento, c.checkout_url, r.email, a.nome as aluno_nome
                FROM contas_receber c
                LEFT JOIN alunos a ON c.aluno_id = a.id
                LEFT JOIN responsaveis r ON c.responsavel_id = r.id OR a.responsavel_id = r.id
                WHERE c.status = 'Pendente' 
                  AND c.data_vencimento = CURRENT_DATE
                  AND c.aviso_d0_enviado = FALSE
                  AND c.checkout_url IS NOT NULL
                  AND r.email IS NOT NULL
            """
            contas_d0 = await conn.fetch(query_d0)
            
            for conta in contas_d0:
                print(f"[ROBÔ COBRANÇA] Enviando D-0 para fatura {conta['id']}...")
                assunto = "Aviso: Mensalidade Escolar vence HOJE"
                corpo = f"""
                <p>Atenção,</p>
                <p>A mensalidade escolar do(a) aluno(a) <strong>{conta['aluno_nome']}</strong> no valor de <strong>R$ {conta['valor']:.2f}</strong> vence <strong>HOJE</strong>.</p>
                <p>Evite multas e juros acessando o link abaixo para realizar o pagamento:</p>
                <p><a href="{conta['checkout_url']}">Clique aqui para pagar</a></p>
                <p>Atenciosamente,<br>Secretaria Escolar</p>
                """
                
                # Descomentar para enviar e-mail real
                # if enviar_email(conta['email'], assunto, corpo):
                #     await conn.execute("UPDATE contas_receber SET aviso_d0_enviado = TRUE WHERE id = $1::uuid", conta['id'])
                
                # Simulação para MVP
                print(f"[ROBÔ COBRANÇA] [SIMULADO] E-mail D-0 enviado para {conta['email']}")
                await conn.execute("UPDATE contas_receber SET aviso_d0_enviado = TRUE WHERE id = $1::uuid", conta['id'])

        except Exception as e:
            print(f"[ROBÔ COBRANÇA] Erro fatal na varredura: {e}")
        break

def iniciar_robo_cobranca():
    """
    Inicializa o scheduler de cobrança e agenda a tarefa diária.
    """
    # Agendado para rodar todos os dias às 08:00
    scheduler_cobranca.add_job(varrer_e_notificar, 'cron', hour=8, minute=0)
    scheduler_cobranca.start()
    print("[ROBÔ COBRANÇA] Ativado. Varredura agendada para 08:00h diariamente.")
