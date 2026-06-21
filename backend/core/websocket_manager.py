from typing import Dict, List



from fastapi import WebSocket





class ConnectionManager:

    



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

        

        for ws in list(self.rooms.get(room_id, [])):

            await ws.send_json(message)







manager = ConnectionManager()

