from fastapi import Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer

# Định nghĩa scheme Bearer cho Swagger UI (logic check thật đã nằm ở Middleware)
token_auth_scheme = HTTPBearer()

# Role-based access control (RBAC) dependency
def require_role(role: str | list[str]):
    async def role_checker(request: Request, _token=Depends(token_auth_scheme)):
        user = getattr(request.state, "user", None)
        if user is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
        
        user_role = user.get("role")
        allowed_roles = [role] if isinstance(role, str) else role
        if user_role not in allowed_roles:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Insufficient permissions")
        return user
    return Depends(role_checker)