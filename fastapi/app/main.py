# main.py
import os
import logging
from fastapi import FastAPI
from app.routes import router
from app.auth_routes import router as auth_router

# logger 設定（uvicorn / ECS / CloudWatch 想定）
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()

# Startup log
@app.on_event("startup")
async def startup_log():
    logger.info("=== Application startup ===")
    logger.info(f"APP_ENV        = {os.getenv('APP_ENV')}")
    logger.info(f"AWS_REGION     = {os.getenv('AWS_REGION')}")
    logger.info(f"DYNAMODB_TABLE = {os.getenv('DYNAMODB_TABLE')}")


# ルーターを登録
app.include_router(router)
app.include_router(auth_router)

@app.get("/ping")
def ping():
    return {"message": "pong"}

# TODO: 本番では消す
@app.get("/secret-check")
def secret_check():
    return {
        "env": os.getenv("APP_ENV"),
        "secret": os.getenv("FASTAPI_JWT_SECRET")
    }