"""WebSocket connection manager for KDS (Kitchen Display System).

A single process-global instance `kds_manager` is used across all requests.
"""
from __future__ import annotations

import asyncio
import json
from collections import defaultdict
from typing import DefaultDict

from fastapi import WebSocket


class KDSManager:
    """Manages WebSocket connections grouped by KDS zone (e.g. 'kitchen', 'bar')."""

    def __init__(self) -> None:
        # zone -> set of active WebSocket connections
        self._connections: DefaultDict[str, set[WebSocket]] = defaultdict(set)
        
        # POS connections (all cashiers get the same broadcast)
        self._pos_connections: set[WebSocket] = set()
        
        # user_id -> set of active WebSocket connections (for direct notification)
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
        """Send a JSON payload to all connected clients in the given zone."""
        message = json.dumps(payload)
        dead: list[WebSocket] = []

        async with self._lock:
            targets = set(self._connections[zone])  # snapshot to avoid mutation during iteration

        for ws in targets:
            try:
                await ws.send_text(message)
            except Exception:  # client disconnected mid-flight
                dead.append(ws)

        # Clean up dead connections
        if dead:
            async with self._lock:
                for ws in dead:
                    self._connections[zone].discard(ws)

    async def broadcast_new_order_items(self, items: list[dict]) -> None:
        """
        Group order items by zone and broadcast each batch.

        Each item dict is expected to have a 'zone' key matching a KDS zone.
        """
        by_zone: DefaultDict[str, list[dict]] = defaultdict(list)
        for item in items:
            zone = item.get("zone", "kitchen")
            by_zone[zone].append(item)

        for zone, zone_items in by_zone.items():
            event = {"event": "new_order_items", "items": zone_items}
            await self.broadcast_to_zone(zone, event)

    # ── POS WebSocket ────────────────────────────────────────────────────────────

    async def connect_pos(self, websocket: WebSocket) -> None:
        await websocket.accept()
        async with self._lock:
            self._pos_connections.add(websocket)

    async def disconnect_pos(self, websocket: WebSocket) -> None:
        async with self._lock:
            self._pos_connections.discard(websocket)

    async def broadcast_pos_event(self, event: dict) -> None:
        """Broadcast events like Table Status change to all POS clients."""
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

    # ── Staff WebSocket ──────────────────────────────────────────────────────────

    async def connect_staff(self, websocket: WebSocket, user_id: str) -> None:
        await websocket.accept()
        async with self._lock:
            self._staff_connections[user_id].add(websocket)

    async def disconnect_staff(self, websocket: WebSocket, user_id: str) -> None:
        async with self._lock:
            self._staff_connections[user_id].discard(websocket)

    async def broadcast_staff_event(self, event: dict) -> None:
        """Push notification to ALL connected staff (e.g. food is ready for ANY table)."""
        message = json.dumps(event)
        dead: list[tuple[str, WebSocket]] = []
        
        async with self._lock:
            # Snapshot all staff sockets
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
        """Push a direct notification to a specific staff member (e.g. food is ready)."""
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



# Process-global singleton — imported by orders/services.py after order commit
kds_manager = KDSManager()
