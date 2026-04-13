from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import asyncio
from routers import health, convert, download, audio
from utils.cleanup import start_cleanup_loop

app = FastAPI(title="Formatica Backend", version="1.0.0")

app.add_middleware(CORSMiddleware, allow_origins=["*"],
    allow_methods=["GET","POST","OPTIONS"], allow_headers=["*"])

app.include_router(health.router, prefix="/health")
app.include_router(convert.router, prefix="/convert")
app.include_router(download.router, prefix="/download")
app.include_router(audio.router, prefix="/audio")

# Add these only if router files exist:
try:
    from routers.video import router as video_router
    app.include_router(video_router, prefix="/video")
except: pass
try:
    from routers.image_convert import router as image_router
    app.include_router(image_router, prefix="/image")
except: pass
try:
    from routers.pdf_tools import router as pdf_router
    app.include_router(pdf_router, prefix="/pdf")
except: pass

@app.get("/")
def root():
    return {"status":"ok","service":"Formatica Backend","version":"1.0.0"}

@app.on_event("startup")
async def startup():
    asyncio.create_task(start_cleanup_loop())
    print("Formatica backend started")
