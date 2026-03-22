# auth_routes.py
import os
from fastapi import APIRouter, Request, Depends, Form
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from app.auth import create_access_token, require_login, require_role, oauth
from fastapi import HTTPException
from jose import jwt

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

    if not redirect_uri:
        raise RuntimeError("COGNITO_REDIRECT_URI not set")

    return await oauth.cognito.authorize_redirect(
        request,
        redirect_uri=redirect_uri
    )

@router.get("/auth/callback")
async def auth_callback(request: Request):

    print("SESSION:", request.session)

    try:
        token = await oauth.cognito.authorize_access_token(request)
    except Exception as e:
        print("OAuth error:", e)
        raise HTTPException(status_code=401, detail="OAuth failed")
    
    userinfo = token.get("userinfo")

    if not userinfo:
        id_token = token["id_token"]
        userinfo = jwt.get_unverified_claims(id_token)

    print("userinfo:", userinfo)

    sub = userinfo["sub"]
    groups = userinfo.get("cognito:groups", [])

    if not sub:
        raise HTTPException(status_code=500, detail="sub not found")

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

    response = RedirectResponse("/admin", status_code=303)

    response.set_cookie(
        key="access_token",
        value=jwt_token,
        httponly=True,
        samesite="lax",
        secure = (APP_ENV != "local"),
        max_age=1800,
        path="/",
    )

    return response

@router.get("/logout")
def logout():

    domain = os.getenv("COGNITO_DOMAIN")

    logout_uri = os.getenv("COGNITO_LOGOUT_URI")

    params = (
        f"?client_id={os.getenv('COGNITO_CLIENT_ID')}"
        f"&logout_uri={logout_uri}"
    )

    logout_url = f"{domain}/logout"

    response = RedirectResponse(logout_url + params)
    response.delete_cookie("access_token")
    return response

@router.get("/admin", response_class=HTMLResponse)
def admin_page(
    request: Request,
    user=Depends(require_role("admin")),
):
    return templates.TemplateResponse(
        "admin.html",
        {"request": request, "user": user},
    )
