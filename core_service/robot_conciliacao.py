import asyncio
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from deps import get_db
from services.mercadopago_service import mp_service

scheduler = AsyncIOScheduler()

async def verificar_pagamentos_pendentes():
    """
    Robô de Conciliação Ativa
    Busca contas pendentes que atingiram a hora de 'proxima_consulta'
    e consulta o status real no Mercado Pago.
    """
    print("[ROBÔ] Iniciando varredura de conciliação de pagamentos...")
    
    async for conn in get_db():
        try:
            # Seleciona as contas pendentes que devem ser consultadas e que possuem preference_id (link gerado)
            query = """
                SELECT id, preference_id, tentativas_consulta 
                FROM contas_receber 
                WHERE status = 'Pendente' 
                  AND preference_id IS NOT NULL 
                  AND tentativas_consulta < 5 
                  AND proxima_consulta <= NOW()
            """
            contas = await conn.fetch(query)
            
            for conta in contas:
                conta_id = conta["id"]
                tentativas = conta["tentativas_consulta"]
                
                print(f"[ROBÔ] Consultando fatura {conta_id} (Checkout Pro) - Tentativa {tentativas + 1}/5")
                
                try:
                    # Busca os pagamentos atrelados a esta referência (conta_id)
                    pagamentos = await mp_service.buscar_pagamentos_por_referencia(str(conta_id))
                    
                    status_interno = "Pendente"
                    mp_payment_id = None
                    
                    # Analisa se há algum pagamento aprovado
                    for pag in pagamentos:
                        if pag.get("status") == "approved":
                            status_interno = "Pago"
                            mp_payment_id = pag.get("id")
                            break
                        elif pag.get("status") in ["rejected", "cancelled", "refunded"]:
                            # Guarda o último status, mas continua procurando pra ver se tem um aprovado depois
                            status_interno = "Cancelado"
                            mp_payment_id = pag.get("id")
                            
                    if status_interno == "Pago":
                        # Sucesso
                        await conn.execute(
                            "UPDATE contas_receber SET status = 'Pago', mp_payment_id = $1 WHERE id = $2::uuid", 
                            str(mp_payment_id), conta_id
                        )
                        print(f"[ROBÔ] Fatura {conta_id} aprovada via Checkout Pro!")
                        
                    elif status_interno == "Cancelado":
                        # Cancelado/Recusado
                        await conn.execute(
                            "UPDATE contas_receber SET status = 'Cancelado', mp_payment_id = $1 WHERE id = $2::uuid", 
                            str(mp_payment_id), conta_id
                        )
                        print(f"[ROBÔ] Fatura {conta_id} cancelada/rejeitada.")
                        
                    else:
                        # Ainda pendente (nenhum pagamento aprovado/rejeitado encontrado)
                        nova_tentativa = tentativas + 1
                        if nova_tentativa >= 5:
                            await conn.execute(
                                "UPDATE contas_receber SET status = 'Atrasado', tentativas_consulta = $1 WHERE id = $2::uuid", 
                                nova_tentativa, conta_id
                            )
                            print(f"[ROBÔ] Fatura {conta_id} esgotou as tentativas e foi marcada como Atrasada.")
                        else:
                            await conn.execute(
                                "UPDATE contas_receber SET tentativas_consulta = $1, proxima_consulta = NOW() + INTERVAL '20 minutes' WHERE id = $2::uuid", 
                                nova_tentativa, conta_id
                            )
                            print(f"[ROBÔ] Fatura {conta_id} continua pendente. Próxima consulta em 20 minutes.")
                            
                except Exception as e:
                    print(f"[ROBÔ] Erro ao consultar MP para fatura {conta_id}: {e}")
                    
        except Exception as e:
            print(f"[ROBÔ] Erro fatal na varredura: {e}")
        # Encerra o loop do gerador após a primeira conexão
        break

def iniciar_robo():
    """
    Inicializa o scheduler e agenda a tarefa.
    """
    scheduler.add_job(verificar_pagamentos_pendentes, 'interval', minutes=5)
    scheduler.start()
    print("[ROBÔ] Robô de Conciliação de Pagamentos ativado. Varredura a cada 5 minutos.")
