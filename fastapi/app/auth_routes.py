# app/auth_routes.py
from fastapi import APIRouter, Request, Form, Depends
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from app.auth import create_access_token, require_login

router = APIRouter()
templates = Jinja2Templates(directory="templates")

@router.get("/login", response_class=HTMLResponse)
def login_page(request: Request):
    return templates.TemplateResponse("login.html", {"request": request})

@router.post("/login")
def login(username: str = Form(...), password: str = Form(...)):
    # PoC用 仮認証
    if username != "admin" or password != "password":
        return RedirectResponse("/login", status_code=303)

    token = create_access_token(sub=username, role="admin")

    response = RedirectResponse("/admin", status_code=303)
    response.set_cookie(
        key="access_token",
        value=token,
        httponly=True,
        samesite="lax",
        secure=False,  # HTTPS化後にTrue
        max_age=1800,
        path="/",
    )
    return response

@router.get("/admin", response_class=HTMLResponse)
def admin_page(
    request: Request,
    user=Depends(require_login),
):
    return templates.TemplateResponse(
        "admin.html",
        {"request": request, "user": user},
    )
