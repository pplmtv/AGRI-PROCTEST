# auth.py
import os
import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import jwt, JWTError

# ======================
# Config
# ======================
SECRET_KEY = os.environ["FASTAPI_JWT_SECRET"]
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

ISSUER = "agri-poc"
AUDIENCE = "agri-poc-users"

security = HTTPBearer(auto_error=False)

# ======================
# Token Create
# ======================
def create_access_token(user_id: str, role: str) -> str:
    now = datetime.now(timezone.utc)

    payload = {
        "iss": ISSUER,
        "aud": AUDIENCE,
        "sub": user_id,
        "role": role,
        "iat": now,
        "exp": now + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES),
        "jti": str(uuid.uuid4()),
    }

    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

# ======================
# Token Decode
# ======================
def decode_token(token: str) -> dict:
    try:
        return jwt.decode(
            token,
            SECRET_KEY,
            algorithms=[ALGORITHM],
            audience=AUDIENCE,
            issuer=ISSUER,
        )
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )

# ======================
# Dependency
# ======================
def require_login(
    request: Request,
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
) -> dict:
    token: Optional[str] = None

    # ① Authorization Header
    if credentials:
        token = credentials.credentials

    # ② HttpOnly Cookie
    if not token:
        token = request.cookies.get("access_token")

    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
        )

    return decode_token(token)
