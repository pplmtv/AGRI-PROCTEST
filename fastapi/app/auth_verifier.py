# auth_verifier.py

import os
from jose import jwt, JWTError
from fastapi import HTTPException, status

SECRET_KEY = os.environ["FASTAPI_JWT_SECRET"]
ALGORITHM = "HS256"
ISSUER = "agri-poc"
AUDIENCE = "agri-poc-users"

class LocalJWTVerifier:
    def verify(self, token: str) -> dict:
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