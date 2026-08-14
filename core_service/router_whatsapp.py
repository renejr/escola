from fastapi import APIRouter, Depends
from deps import require_role
from services.whatsapp_service import obter_status_conexao, gerar_qr_code

router = APIRouter(prefix="/core/whatsapp", tags=["WhatsApp"])

@router.get("/status")
async def status(tenant: dict = Depends(require_role(['admin', 'diretor']))):
    return await obter_status_conexao()

@router.get("/qr")
async def qr_code(tenant: dict = Depends(require_role(['admin', 'diretor']))):
    return await gerar_qr_code()
