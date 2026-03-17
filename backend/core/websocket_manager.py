from typing import Dict, List

from fastapi import WebSocket


class ConnectionManager:
    """
    Room-based WebSocket manager.

    Rooms are identified by a string key, e.g.:
      - "kds:kitchen"   — Kitchen Display System zone
      - "kds:bar"       — Bar Display System zone
      - "staff:42"      — Staff member with user_id=42
      - "tables"        — POS table-status updates
    """

    def __init__(self) -> None:
        self.rooms: Dict[str, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, room_id: str) -> None:
        await websocket.accept()
        self.rooms.setdefault(room_id, []).append(websocket)

    def disconnect(self, websocket: WebSocket, room_id: str) -> None:
        room = self.rooms.get(room_id, [])
        if websocket in room:
            room.remove(websocket)

    async def broadcast(self, room_id: str, message: dict) -> None:
        """Send a JSON payload to every connection in the given room."""
        for ws in list(self.rooms.get(room_id, [])):
            await ws.send_json(message)


# Singleton — import this in any module that needs to broadcast
manager = ConnectionManager()
