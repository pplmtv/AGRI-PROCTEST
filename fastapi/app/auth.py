# auth.py
import os
import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional
from fastapi import Depends, HTTPException, Request, status, APIRouter
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from fastapi.responses import RedirectResponse
from .auth_verifier import LocalJWTVerifier
from jose import jwt
from authlib.integrations.starlette_client import OAuth
from dotenv import load_dotenv

load_dotenv()

router = APIRouter()

oauth = OAuth()

oauth.register(
    name="cognito",
    client_id=os.getenv("COGNITO_CLIENT_ID"),
    client_secret=os.getenv("COGNITO_CLIENT_SECRET"),
    server_metadata_url=f"https://cognito-idp.{os.getenv('COGNITO_REGION')}.amazonaws.com/{os.getenv('COGNITO_USER_POOL_ID')}/.well-known/openid-configuration",
    client_kwargs={
        "scope": "openid email profile",
    },
)

verifier = LocalJWTVerifier()

# ======================
# Config
# ======================
SECRET_KEY = os.environ["FASTAPI_JWT_SECRET"]
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

ISSUER = "agri-poc"
AUDIENCE = "agri-poc-users"

security = HTTPBearer(auto_error=False)

ROLE_LEVEL = {
    "family": 1,
    "farmer": 2,
    "admin": 3,
}

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
    return verifier.verify(token)

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

def require_role(required_role: str):
    def role_checker(user=Depends(require_login)):
        user_role = user.get("role")

        if ROLE_LEVEL.get(user_role, 0) < ROLE_LEVEL.get(required_role, 0):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Forbidden"
            )
        return user
    return role_checker