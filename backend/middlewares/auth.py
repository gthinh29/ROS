from fastapi import Request
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from jose import jwt
from datetime import datetime, timezone
from core.config import settings

IS_PUBLIC = False 


_EXCLUDED_EXACT = {"/auth/login", "/auth/signup", "/health", "/favicon.ico"}

_EXCLUDED_PREFIXES = ("/menu", "/ws", "/reservations", "/orders", "/docs", "/openapi.json", "/redoc", "/tables/available")


class JWTAuthenticationMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        path = request.url.path
        authorization = request.headers.get("Authorization")
        is_public_path = path in _EXCLUDED_EXACT or path.startswith(_EXCLUDED_PREFIXES)

        
        if not authorization or not authorization.startswith("Bearer "):
            if is_public_path:
                return await call_next(request)
            return JSONResponse(status_code=401, content={"detail": "Token missing or invalid format"})
        
        
        token = authorization.replace("Bearer ", "")
        
        try:
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])

            
            if datetime.now(timezone.utc) > datetime.fromtimestamp(payload["exp"], tz=timezone.utc):
                if is_public_path: return await call_next(request) 
                return JSONResponse(status_code=401, content={"detail": "Token has expired"})

            request.state.user = payload
            return await call_next(request)

        except (jwt.ExpiredSignatureError, jwt.JWTError):
            
            if is_public_path:
                return await call_next(request)
            return JSONResponse(status_code=401, content={"detail": "Invalid or expired token"})
