

from __future__ import annotations



import asyncio

import json

from collections import defaultdict

from typing import DefaultDict



from fastapi import WebSocket





class KDSManager:

    



    def __init__(self) -> None:

        

        self._connections: DefaultDict[str, set[WebSocket]] = defaultdict(set)

        

        

        self._pos_connections: set[WebSocket] = set()

        

        

        self._staff_connections: DefaultDict[str, set[WebSocket]] = defaultdict(set)

        

        self._lock = asyncio.Lock()





    async def connect(self, websocket: WebSocket, zone: str) -> None:

        await websocket.accept()

        async with self._lock:

            self._connections[zone].add(websocket)



    async def disconnect(self, websocket: WebSocket, zone: str) -> None:

        async with self._lock:

            self._connections[zone].discard(websocket)



    async def broadcast_to_zone(self, zone: str, payload: dict) -> None:

        

        message = json.dumps(payload)

        dead: list[WebSocket] = []



        async with self._lock:

            targets = set(self._connections[zone])  



        for ws in targets:

            try:

                await ws.send_text(message)

            except Exception:  

                dead.append(ws)



        

        if dead:

            async with self._lock:

                for ws in dead:

                    self._connections[zone].discard(ws)



    async def broadcast_new_order_items(self, items: list[dict]) -> None:

        

        by_zone: DefaultDict[str, list[dict]] = defaultdict(list)

        for item in items:

            zone = item.get("zone", "kitchen")

            by_zone[zone].append(item)



        for zone, zone_items in by_zone.items():

            event = {"event": "new_order_items", "items": zone_items}

            await self.broadcast_to_zone(zone, event)



    



    async def connect_pos(self, websocket: WebSocket) -> None:

        await websocket.accept()

        async with self._lock:

            self._pos_connections.add(websocket)



    async def disconnect_pos(self, websocket: WebSocket) -> None:

        async with self._lock:

            self._pos_connections.discard(websocket)



    async def broadcast_pos_event(self, event: dict) -> None:

        

        message = json.dumps(event)

        dead: list[WebSocket] = []

        async with self._lock:

            targets = set(self._pos_connections)

            

        for ws in targets:

            try:

                await ws.send_text(message)

            except Exception:

                dead.append(ws)

                

        if dead:

            async with self._lock:

                for ws in dead:

                    self._pos_connections.discard(ws)



    



    async def connect_staff(self, websocket: WebSocket, user_id: str) -> None:

        await websocket.accept()

        async with self._lock:

            self._staff_connections[user_id].add(websocket)



    async def disconnect_staff(self, websocket: WebSocket, user_id: str) -> None:

        async with self._lock:

            self._staff_connections[user_id].discard(websocket)



    async def broadcast_staff_event(self, event: dict) -> None:

        

        message = json.dumps(event)

        dead: list[tuple[str, WebSocket]] = []

        

        async with self._lock:

            

            targets = []

            for uid, sockets in self._staff_connections.items():

                for ws in sockets:

                    targets.append((uid, ws))

                    

        for uid, ws in targets:

            try:

                await ws.send_text(message)

            except Exception:

                dead.append((uid, ws))

                

        if dead:

            async with self._lock:

                for uid, ws in dead:

                    self._staff_connections[uid].discard(ws)







    async def send_to_staff(self, user_id: str, event: dict) -> None:

        

        message = json.dumps(event)

        dead: list[WebSocket] = []

        async with self._lock:

            targets = set(self._staff_connections[user_id])

            

        for ws in targets:

            try:

                await ws.send_text(message)

            except Exception:

                dead.append(ws)

                

        if dead:

            async with self._lock:

                for ws in dead:

                    self._staff_connections[user_id].discard(ws)









kds_manager = KDSManager()

