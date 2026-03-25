from fastapi import Depends, HTTPException, status, Request

# Role-based access control (RBAC) dependency
def require_role(role: str):
    async def role_checker(request: Request):
        user = getattr(request.state, "user", None)
        if user is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
        if role not in user.get("role"):
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Insufficient permissions")
        return user
    return Depends(role_checker)