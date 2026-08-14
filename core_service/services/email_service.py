import os
from fastapi_mail import FastMail, MessageSchema, ConnectionConfig, MessageType
from dotenv import load_dotenv

load_dotenv()

conf = ConnectionConfig(
    MAIL_USERNAME=os.getenv("SMTP_USER", "escola@mdxhq.com.br"),
    MAIL_PASSWORD=os.getenv("SMTP_PASS", ""),
    MAIL_FROM=os.getenv("SMTP_FROM_EMAIL", "escola@mdxhq.com.br"),
    MAIL_PORT=int(os.getenv("SMTP_PORT", 465)),
    MAIL_SERVER=os.getenv("SMTP_HOST", "smtp.titan.email"),
    MAIL_FROM_NAME=os.getenv("SMTP_FROM_NAME", "SaaS Escolar"),
    MAIL_STARTTLS=False,
    MAIL_SSL_TLS=True,
    USE_CREDENTIALS=True,
    VALIDATE_CERTS=True
)

async def enviar_email_notificacao(destinatario: str, assunto: str, corpo_html: str):
    """
    Envia um e-mail HTML utilizando o serviço configurado.
    """
    try:
        message = MessageSchema(
            subject=assunto,
            recipients=[destinatario],
            body=corpo_html,
            subtype=MessageType.html
        )
        fm = FastMail(conf)
        await fm.send_message(message)
        print(f"E-mail enviado com sucesso para {destinatario}")
    except Exception as e:
        print(f"Falha ao enviar e-mail para {destinatario}: {e}")
