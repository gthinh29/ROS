from fastapi import Request
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from jose import jwt
from datetime import datetime, timezone
from core.config import settings

IS_PUBLIC = False # Set to False in production to enforce authentication on all routes by default

# Exact path matches that skip JWT validation
_EXCLUDED_EXACT = {"/auth/login", "/auth/signup", "/health", "/favicon.ico"}
# Prefix matches — any URL starting with these is public (skip auth IF no token provided)
_EXCLUDED_PREFIXES = ("/menu", "/ws", "/reservations", "/orders", "/docs", "/openapi.json", "/redoc")


class JWTAuthenticationMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        path = request.url.path
        authorization = request.headers.get("Authorization")
        is_public_path = path in _EXCLUDED_EXACT or path.startswith(_EXCLUDED_PREFIXES)

        # 1. Nếu không có token:
        if not authorization or not authorization.startswith("Bearer "):
            if is_public_path:
                return await call_next(request)
            return JSONResponse(status_code=401, content={"detail": "Token missing or invalid format"})
        
        # 2. Nếu CÓ token: Luôn thử giải mã
        token = authorization.replace("Bearer ", "")
        
        try:
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])

            # Kiểm tra hết hạn
            if datetime.now(timezone.utc) > datetime.fromtimestamp(payload["exp"], tz=timezone.utc):
                if is_public_path: return await call_next(request) # Bỏ qua cho public route
                return JSONResponse(status_code=401, content={"detail": "Token has expired"})

            request.state.user = payload
            return await call_next(request)

        except (jwt.ExpiredSignatureError, jwt.JWTError):
            # Nếu route là public but token sai/hết hạn -> Vẫn cho qua (nhưng state.user rỗng)
            if is_public_path:
                return await call_next(request)
            return JSONResponse(status_code=401, content={"detail": "Invalid or expired token"})
