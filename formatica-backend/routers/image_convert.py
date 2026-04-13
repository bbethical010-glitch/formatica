from fastapi import APIRouter, UploadFile, Form, HTTPException
from fastapi.responses import Response
from PIL import Image
import io

router = APIRouter()

@router.post("/convert")
async def convert_image(file: UploadFile,
    output_format: str = Form(...), quality: int = Form(85)):
    allowed_in = {"jpg","jpeg","png","webp","bmp","gif","tiff"}
    allowed_out = {"jpg","png","webp","bmp","gif"}
    ext = file.filename.split(".")[-1].lower()
    if ext not in allowed_in: raise HTTPException(400,"Unsupported input")
    if output_format not in allowed_out: raise HTTPException(400,"Unsupported output")
    data = await file.read()
    img = Image.open(io.BytesIO(data))
    if output_format in ("jpg","jpeg") and img.mode in ("RGBA","P","LA"):
        img = img.convert("RGB")
    buf = io.BytesIO()
    fmt = {"jpg":"JPEG","jpeg":"JPEG","png":"PNG","webp":"WEBP","bmp":"BMP","gif":"GIF"}
    save_fmt = fmt.get(output_format,"PNG")
    if save_fmt=="JPEG": img.save(buf,format=save_fmt,quality=quality,optimize=True)
    else: img.save(buf,format=save_fmt)
    return Response(content=buf.getvalue(),media_type="application/octet-stream",
        headers={"Content-Disposition":f"attachment; filename=converted.{output_format}"})
