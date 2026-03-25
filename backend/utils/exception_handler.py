from fastapi import Request, HTTPException
from fastapi.responses import JSONResponse
from starlette.status import HTTP_500_INTERNAL_SERVER_ERROR

async def http_exception_handler(request: Request, exc: HTTPException):
    status_type_map = {
        400: "Bad Request",
        401: "Unauthorized",
        403: "Forbidden",
        404: "Not Found",
        405: "Method Not Allowed",
        409: "Conflict",
        422: "Unprocessable Entity",
    }
    type_str = status_type_map.get(exc.status_code, "HTTPException")

    return JSONResponse(        
        status_code=exc.status_code,
        content={
            "error": {
                "type": type_str,
                "message": exc.detail
            },
            "path": request.url.path
        },
    )

async def generic_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": {
                "type": "Internal Server Error",
                "message": str(exc)
            },
            "path": request.url.path 
        },
    )