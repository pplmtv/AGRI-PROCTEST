# app/auth.py
import os
from datetime import datetime, timedelta
from jose import jwt, JWTError
from fastapi import HTTPException, status, Request

SECRET_KEY = os.environ["FASTAPI_JWT_SECRET"]
ALGORITHM = "HS256"

def create_access_token(sub: str, role: str, minutes: int = 30):
    payload = {
        "sub": sub,
        "role": role,
        "exp": datetime.utcnow() + timedelta(minutes=minutes),
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

def verify_token(token: str):
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        )

def require_login(request: Request):
    token = request.cookies.get("access_token")
    if not token:
        raise HTTPException(status_code=401, detail="Not authenticated")
    return verify_token(token)
