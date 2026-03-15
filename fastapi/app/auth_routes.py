# auth_routes.py
import os
from fastapi import APIRouter, Request, Depends, Form
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from app.auth import create_access_token, require_login, require_role, oauth
from fastapi import HTTPException

APP_ENV = os.getenv("APP_ENV", "local")

router = APIRouter()
templates = Jinja2Templates(directory="templates")

# 仮ユーザーストア（PoC用）
USER_STORE = {
    "admin": {
        "password": "password",
        "role": "admin",
    },
    "farmer": {
        "password": "password",
        "role": "farmer",
    },
    "family": {
        "password": "password",
        "role": "family",
    },
}

@router.post("/login")
def local_login(
    username: str = Form(...),
    password: str = Form(...)
):
    if APP_ENV != "local":
        raise HTTPException(status_code=404)

    user = USER_STORE.get(username)

    if not user or user["password"] != password:
        return RedirectResponse("/login", status_code=303)

    token = create_access_token(
        user_id=username,
        role=user["role"],
    )

    response = RedirectResponse("/admin", status_code=303)

    response.set_cookie(
        key="access_token",
        value=token,
        httponly=True,
        samesite="lax",
        secure=False,
        max_age=1800,
        path="/",
    )

    return response

@router.get("/login")
async def login(request: Request):

    if APP_ENV == "local":
        return templates.TemplateResponse(
            "login.html",
            {"request": request}
        )

    redirect_uri = os.getenv("COGNITO_REDIRECT_URI")

    return await oauth.cognito.authorize_redirect(
        request,
        redirect_uri
    )

@router.get("/auth/callback")
async def auth_callback(request: Request):

    token = await oauth.cognito.authorize_access_token(request)
    userinfo = token.get("userinfo") or token["id_token_claims"]
    sub = userinfo["sub"]
    groups = userinfo.get("cognito:groups", [])

    if "admin" in groups:
        role = "admin"
    elif "farmer" in groups:
        role = "farmer"
    else:
        role = "family"

    jwt_token = create_access_token(
        user_id=sub,
        role=role,
    )

    response = RedirectResponse("/admin")

    response.set_cookie(
        key="access_token",
        value=jwt_token,
        httponly=True,
        samesite="lax",
        secure=True,
        max_age=1800,
        path="/",
    )

    return response

@router.get("/logout")
def logout():

    domain = os.getenv("COGNITO_DOMAIN")

    logout_url = f"{domain}/logout"

    params = (
        f"?client_id={os.getenv('COGNITO_CLIENT_ID')}"
        f"&logout_uri={logout_uri}"
    )

    return RedirectResponse(logout_url + params)

@router.get("/admin", response_class=HTMLResponse)
def admin_page(
    request: Request,
    user=Depends(require_role("admin")),
):
    return templates.TemplateResponse(
        "admin.html",
        {"request": request, "user": user},
    )
