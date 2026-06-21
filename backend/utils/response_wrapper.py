from typing import Generic, TypeVar, Optional

from pydantic import BaseModel



T = TypeVar('T')





class ResponseWrapper(BaseModel, Generic[T]):

    success: bool

    data: Optional[T] = None

    error_message: Optional[str] = None



    @classmethod

    def success_response(cls, data: T) -> 'ResponseWrapper[T]':

        return cls(success=True, data=data)



    @classmethod

    def error_response(cls, error_message: str) -> 'ResponseWrapper[None]':

        return cls(success=False, error_message=error_message) # type: ignore

