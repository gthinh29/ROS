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
        if IS_PUBLIC:
            return await call_next(request)

        path = request.url.path
        authorization = request.headers.get("Authorization")
        
        # If no token is provided, check if the route is allowed to be public
        if not authorization or not authorization.startswith("Bearer "):
            if path in _EXCLUDED_EXACT or path.startswith(_EXCLUDED_PREFIXES):
                return await call_next(request)
            return JSONResponse(status_code=401, content={"detail": "Token missing or invalid format"})
        
        # If a token IS provided, always decode it and attach to request.state.user
        token = authorization.replace("Bearer ", "")
        
        try:
            # Decode and verify the JWT token
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])

            # Check if the token has expired
            if datetime.now(timezone.utc) > datetime.fromtimestamp(payload["exp"], tz=timezone.utc):
                return JSONResponse(status_code=401, content={"detail": "Token has expired"})

            # Save the payload information into the request state for role_access dependency
            request.state.user = payload

        except jwt.ExpiredSignatureError:
            return JSONResponse(status_code=401, content={"detail": "Token has expired"})
        except jwt.JWTError:
            return JSONResponse(status_code=401, content={"detail": "Invalid token"})
        
        return await call_next(request)