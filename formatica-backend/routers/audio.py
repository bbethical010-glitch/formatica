import os
import uuid
import asyncio
import aiofiles
from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Response
from typing import Optional

router = APIRouter()

SUPPORTED_INPUT_EXTENSIONS = {
    "mp4", "mkv", "avi", "mov", "webm", "flv", "mp3", "wav", "flac", "ogg", "m4a", "m4v"
}
SUPPORTED_OUTPUT_FORMATS = {"mp3", "aac", "wav"}

@router.post("/")
async def extract_audio(
    file: UploadFile = File(...),
    output_format: str = Form(...),
    bitrate: str = Form("192k")
):
    # 1. Validate extension
    filename = file.filename or "input"
    ext = filename.split(".")[-1].lower() if "." in filename else ""
    if ext not in SUPPORTED_INPUT_EXTENSIONS:
        raise HTTPException(status_code=400, detail=f"Unsupported input extension: {ext}")

    # 2. Validate output format
    if output_format not in SUPPORTED_OUTPUT_FORMATS:
        raise HTTPException(status_code=400, detail=f"Unsupported output format: {output_format}")

    # 3. job_id
    job_id = uuid.uuid4().hex
    input_path = f"/app/tmp/{job_id}_input.{ext}"
    output_path = f"/app/tmp/{job_id}_output.{output_format}"

    try:
        # 4. Save uploaded file
        async with aiofiles.open(input_path, 'wb') as out_file:
            while content := await file.read(1024 * 1024):  # Read 1MB at a time
                await out_file.write(content)

        # 6. Build ffmpeg command
        if output_format == "wav":
            command = [
                "ffmpeg", "-i", input_path, "-vn",
                "-acodec", "pcm_s16le",
                "-y", output_path
            ]
        else:
            codec = "libmp3lame" if output_format == "mp3" else "aac"
            command = [
                "ffmpeg", "-i", input_path, "-vn",
                "-acodec", codec,
                "-ab", bitrate,
                "-y", output_path
            ]

        # 7. Run ffmpeg
        process = await asyncio.create_subprocess_exec(
            *command,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )

        try:
            stdout, stderr = await asyncio.wait_for(process.communicate(), timeout=120)
        except asyncio.TimeoutError:
            process.kill()
            raise HTTPException(status_code=504, detail="Audio extraction timed out")

        # 8. Check return code
        if process.returncode != 0:
            stderr_text = stderr.decode()
            if "No such file" in stderr_text:
                raise HTTPException(status_code=400, detail="Could not read input file")
            if "Invalid data" in stderr_text:
                raise HTTPException(status_code=400, detail="File appears corrupted or unsupported")
            else:
                print(f"FFmpeg Error: {stderr_text}")
                raise HTTPException(status_code=500, detail="Audio extraction failed")

        # 9. Read output bytes
        async with aiofiles.open(output_path, 'rb') as f:
            output_bytes = await f.read()

        # 11. Return response
        return Response(
            content=output_bytes,
            media_type="application/octet-stream",
            headers={"Content-Disposition": f"attachment; filename=audio.{output_format}"}
        )

    finally:
        # 10. Cleanup
        for path in [input_path, output_path]:
            if os.path.exists(path):
                try:
                    os.remove(path)
                except:
                    pass
