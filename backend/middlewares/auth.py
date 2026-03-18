from fastapi import Request, HTTPException
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from jose import jwt
from datetime import datetime, timezone
from core.config import settings

IS_PUBLIC = True # Set to False in production to enforce authentication on all routes by default
excluded_paths = ["/auth/login", "/auth/signup", "/auth/refresh-token"]
admin_paths = [""] # For special cases like Admin routes that require additional checks (e.g., role-based access control)
class JWTAuthenticationMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        if IS_PUBLIC:
            return await call_next(request)
        # Check if the request path is in the excluded paths
        if request.url.path in excluded_paths:
            return await call_next(request)

        # Get the token from the Authorization header
        authorization = request.headers.get("Authorization")
        if authorization is None or not authorization.startswith("Bearer "):
            return JSONResponse(status_code=401, content={"detail": "Token missing or invalid format"})
        
        token = authorization.replace("Bearer ", "")
        
        try:
            # Decode and verify the JWT token
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])

            # Check if the token has expired
            if datetime.now(timezone.utc) > datetime.fromtimestamp(payload["exp"], tz=timezone.utc):
                return JSONResponse(status_code=401, content={"detail": "Token has expired"})

            # Save the payload information into the request state for later use (if needed)
            request.state.user = payload

        except jwt.ExpiredSignatureError:
            return JSONResponse(status_code=401, content={"detail": "Token has expired"})
        except jwt.PyJWTError:
            return JSONResponse(status_code=401, content={"detail": "Invalid token"})
        
        # Check if the request path is in the admin paths
        if request.url.path in admin_paths:
            user_role = request.state.user.get("role")
            if user_role != "ADMIN":  # Example check for admin role
                return JSONResponse(status_code=403, content={"detail": "Insufficient permissions"})
        
        response = await call_next(request)
        return response