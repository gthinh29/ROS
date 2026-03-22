import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status, WebSocket, WebSocketDisconnect
from fastapi.responses import Response
from sqlalchemy.orm import Session

from core.database import get_db
from core.denpendencies.role_access import require_role
from core.enums import UserRole
from core.ws_manager import kds_manager
from modules.tables import schemas, services

router = APIRouter(prefix="/tables", tags=["Tables"])

IS_ADMIN = UserRole.ADMIN.value
IS_STAFF = [UserRole.ADMIN.value, UserRole.CASHIER.value, UserRole.WAITER.value]

@router.get("", response_model=List[schemas.TableRead])
async def list_tables(
    db: Session = Depends(get_db),
    current_user: dict = require_role(IS_STAFF),
):
    """Retrieve all tables with their current status (For POS/Waiter)."""
    return services.get_tables(db)

@router.post("", response_model=schemas.TableRead, status_code=status.HTTP_201_CREATED)
async def create_table(
    table_in: schemas.TableCreate,
    db: Session = Depends(get_db),
    current_user: dict = require_role(IS_ADMIN),
):
    """Create a new table and auto-generate its QR code token (Admin only)."""
    return services.create_table(db, table_in)

@router.get("/{table_id}/qr", response_class=Response)
async def get_table_qr_code(
    table_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: dict = require_role(IS_ADMIN),
):
    """Download the QR code image (PNG) for a specific table."""
    table = services.get_table(db, table_id)
    if not table:
        raise HTTPException(status_code=404, detail="Table not found")
    
    img_bytes = services.generate_qr_code_png(table.qr_token)
    return Response(content=img_bytes, media_type="image/png")




@router.websocket("/ws/pos")
async def pos_websocket(websocket: WebSocket):
    """WebSocket endpoint for POS devices (Cashier) to track table statuses in real-time."""
    await kds_manager.connect_pos(websocket)
    try:
        while True:
            # POS clients don't send active messages to server for now, just keep-alive ping/pong
            await websocket.receive_text()
    except WebSocketDisconnect:
        await kds_manager.disconnect_pos(websocket)

@router.websocket("/ws/staff/{user_id}")
async def staff_websocket(websocket: WebSocket, user_id: str):
    """WebSocket endpoint for Staff (Waiters) to receive push notifications."""
    await kds_manager.connect_staff(websocket, user_id)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        await kds_manager.disconnect_staff(websocket, user_id)

