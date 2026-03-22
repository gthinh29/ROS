"""KDS WebSocket endpoint — pushes realtime kitchen events to connected clients."""
from __future__ import annotations

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from core.ws_manager import kds_manager

router = APIRouter(prefix="/ws/kds", tags=["KDS"])


@router.websocket("/{zone}")
async def kds_ws_endpoint(websocket: WebSocket, zone: str):
    """
    Connect to the KDS WebSocket for a specific zone.
    
    - zone: 'kitchen' or 'bar'
    
    Client receives JSON events of the form:
    {
      "event": "new_order_items",
      "items": [
        {
          "order_item_id": "...",
          "order_id": "...",
          "menu_item_name": "Cà phê sữa",
          "variant_name": "M",
          "modifier_names": ["Thêm đường"],
          "qty": 2,
          "note": "ít đá",
          "table_id": "...",
          "zone": "bar"
        }
      ]
    }
    """
    await kds_manager.connect(websocket, zone)
    try:
        # Keep connection alive — clients can send ping messages to keep it open
        while True:
            data = await websocket.receive_text()
            # Echo back a pong to keep alive; clients may send {"type": "ping"}
            if data == '{"type":"ping"}' or data == "ping":
                await websocket.send_text('{"type":"pong"}')
    except WebSocketDisconnect:
        await kds_manager.disconnect(websocket, zone)
