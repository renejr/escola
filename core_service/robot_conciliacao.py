import asyncio
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from deps import get_db
from services.mercadopago_service import mp_service

scheduler = AsyncIOScheduler()

async def verificar_pagamentos_pendentes():
    """
    Robô de Conciliação Ativa (Nova Janela de 5 Dias)
    Busca contas pendentes cujo vencimento não excedeu 5 dias de atraso.
    """
    print("[ROBÔ CONCILIAÇÃO] Iniciando varredura...")
    
    async for conn in get_db():
        try:
            # 1. Varredura de contas ativas na Janela Contínua (Vencimento >= Hoje - 5 dias)
            query_ativas = """
                SELECT id, preference_id 
                FROM contas_receber 
                WHERE status = 'Pendente' 
                  AND preference_id IS NOT NULL 
                  AND data_vencimento >= (CURRENT_DATE - INTERVAL '5 days')
            """
            contas = await conn.fetch(query_ativas)
            
            for conta in contas:
                conta_id = conta["id"]
                print(f"[ROBÔ CONCILIAÇÃO] Consultando fatura {conta_id} na janela de 5 dias...")
                
                try:
                    pagamentos = await mp_service.buscar_pagamentos_por_referencia(str(conta_id))
                    status_interno = "Pendente"
                    mp_payment_id = None
                    
                    for pag in pagamentos:
                        if pag.get("status") == "approved":
                            status_interno = "Pago"
                            mp_payment_id = pag.get("id")
                            break
                        elif pag.get("status") in ["rejected", "cancelled", "refunded"]:
                            status_interno = "Cancelado"
                            mp_payment_id = pag.get("id")
                            
                    if status_interno == "Pago":
                        await conn.execute(
                            "UPDATE contas_receber SET status = 'Pago', mp_payment_id = $1 WHERE id = $2::uuid", 
                            str(mp_payment_id), conta_id
                        )
                        print(f"[ROBÔ CONCILIAÇÃO] Fatura {conta_id} aprovada!")
                        
                    elif status_interno == "Cancelado":
                        await conn.execute(
                            "UPDATE contas_receber SET status = 'Cancelado', mp_payment_id = $1 WHERE id = $2::uuid", 
                            str(mp_payment_id), conta_id
                        )
                        print(f"[ROBÔ CONCILIAÇÃO] Fatura {conta_id} cancelada/rejeitada.")
                        
                except Exception as e:
                    print(f"[ROBÔ CONCILIAÇÃO] Erro ao consultar MP para fatura {conta_id}: {e}")
            
            # 2. Auto-arquivamento (D+6): Contas pendentes com Vencimento < Hoje - 5 dias
            query_atrasadas = """
                UPDATE contas_receber 
                SET status = 'Atrasado'
                WHERE status = 'Pendente' 
                  AND data_vencimento < (CURRENT_DATE - INTERVAL '5 days')
                RETURNING id::text
            """
            arquivadas = await conn.fetch(query_atrasadas)
            for arq in arquivadas:
                print(f"[ROBÔ CONCILIAÇÃO] Fatura {arq['id']} esgotou a janela de 5 dias e foi auto-arquivada como Atrasada.")

        except Exception as e:
            print(f"[ROBÔ CONCILIAÇÃO] Erro fatal na varredura: {e}")
        # Encerra o loop do gerador após a primeira conexão
        break

def iniciar_robo():
    """
    Inicializa o scheduler e agenda a tarefa.
    Roda de 1 em 1 hora.
    """
    scheduler.add_job(verificar_pagamentos_pendentes, 'interval', hours=1)
    scheduler.start()
    print("[ROBÔ CONCILIAÇÃO] Ativado. Varredura contínua de 1 em 1 hora.")
