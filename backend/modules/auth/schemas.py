from pydantic import BaseModel, Field

# Schemas for authentication (login, registration, password reset)
class LoginRequest(BaseModel):
    email: str = Field(min_length=11, max_length=100, pattern=r'^\S+@\S+\.\S+$') # at least 11 characters, e.g., user@gmail.com
    password: str = Field(min_length=6, max_length=128)

class LoginResponse(BaseModel):
    access_token: str
    refresh_token: str
    
class RefreshTokenRequest(BaseModel):
    refresh_token: str

class RefreshTokenResponse(BaseModel):
    access_token: str
    refresh_token: str

class UserResetPassword():
    pass

class UserRegisterRequest(BaseModel):
    email: str = Field(min_length=11, max_length=100, pattern=r'^\S+@\S+\.\S+$') # at least 11 characters, e.g.,
    password: str = Field(min_length=6, max_length=128)
    phone: str = Field(min_length=10, max_length=30, pattern=r'^\+?\d{10,30}$') # allows 10-30 digits
