import os
from fastapi import FastAPI
from app.routes import router
from app.auth_routes import router as auth_router

app = FastAPI()

# ルーターを登録
app.include_router(router)
app.include_router(auth_router)

@app.get("/ping")
def ping():
    return {"message": "pong"}

@app.get("/secret-check")
def secret_check():
    return {
        "env": os.getenv("APP_ENV"),
        "secret": os.getenv("FASTAPI_JWT_SECRET")
    }