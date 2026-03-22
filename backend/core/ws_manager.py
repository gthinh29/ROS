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


# Process-global singleton — imported by orders/services.py after order commit
kds_manager = KDSManager()
