"""
FastAPI Hello World Application
Cloud-ready with health checks and metadata endpoints
"""
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import os
import socket
import time
from datetime import datetime

APP_VERSION = os.getenv("APP_VERSION", "1.0.0")
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")
CLOUD_PROVIDER = os.getenv("CLOUD_PROVIDER", "unknown")

app = FastAPI(
    title="MediaShare API",
    description="Phase 1: Hello World with Cloud Metadata",
    version=APP_VERSION
)

class HealthResponse(BaseModel):
    status: str
    timestamp: str
    hostname: str
    environment: str
    cloud_provider: str
    version: str
    uptime_seconds: float

START_TIME = time.time()

@app.get("/", response_model=dict)
async def root():
    return {
        "message": "Welcome to MediaShare API",
        "version": APP_VERSION,
        "docs": "/docs",
        "health": "/health"
    }

@app.get("/health", response_model=HealthResponse)
async def health_check():
    return HealthResponse(
        status="healthy",
        timestamp=datetime.utcnow().isoformat(),
        hostname=socket.gethostname(),
        environment=ENVIRONMENT,
        cloud_provider=CLOUD_PROVIDER,
        version=APP_VERSION,
        uptime_seconds=round(time.time() - START_TIME, 2)
    )

@app.get("/metadata")
async def instance_metadata():
    return {
        "hostname": socket.gethostname(),
        "environment": ENVIRONMENT,
        "cloud_provider": CLOUD_PROVIDER,
        "version": APP_VERSION,
    }

@app.get("/ready")
async def readiness_check():
    return {"status": "ready"}

@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal Server Error",
            "detail": str(exc),
            "timestamp": datetime.utcnow().isoformat()
        }
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
