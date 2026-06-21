

from __future__ import annotations



from fastapi import APIRouter, WebSocket, WebSocketDisconnect



from core.ws_manager import kds_manager



router = APIRouter(prefix="/ws", tags=["WebSockets"])





@router.websocket("/kds/{zone}")

async def kds_ws_endpoint(websocket: WebSocket, zone: str):

    

    await kds_manager.connect(websocket, zone)

    try:

        

        while True:

            data = await websocket.receive_text()

            

            if data == '{"type":"ping"}' or data == "ping":

                await websocket.send_text('{"type":"pong"}')

    except WebSocketDisconnect:

        await kds_manager.disconnect(websocket, zone)



@router.websocket("/pos")

async def pos_websocket(websocket: WebSocket):

    

    await kds_manager.connect_pos(websocket)

    try:

        while True:

            

            await websocket.receive_text()

    except WebSocketDisconnect:

        await kds_manager.disconnect_pos(websocket)



@router.websocket("/staff/{user_id}")

async def staff_websocket(websocket: WebSocket, user_id: str):

    

    await kds_manager.connect_staff(websocket, user_id)

    try:

        while True:

            await websocket.receive_text()

    except WebSocketDisconnect:

        await kds_manager.disconnect_staff(websocket, user_id)

