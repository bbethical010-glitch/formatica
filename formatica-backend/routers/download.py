import os
import uuid
import glob
import asyncio

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from fastapi.responses import Response

from utils.validators import is_valid_url

router = APIRouter()

TMP_DIR = "/app/tmp"


class DownloadRequest(BaseModel):
    url: str
    format: str = "mp4"


@router.post("/")
async def download_media(req: DownloadRequest):
    # Validate URL
    if not is_valid_url(req.url):
        raise HTTPException(status_code=400, detail="Invalid URL")

    # Validate format
    fmt = req.format.lower().strip()
    if fmt not in ("mp4", "mp3"):
        raise HTTPException(status_code=400, detail="Unsupported format")

    # Generate unique job ID
    job_id = uuid.uuid4().hex
    output_template = f"{TMP_DIR}/{job_id}.%(ext)s"

    # Build yt-dlp command
    if fmt == "mp4":
        cmd = [
            "python3", "-m", "yt_dlp",
            "--no-playlist",
            "-f", "bestvideo[ext=mp4][height<=720]+bestaudio[ext=m4a]/best[ext=mp4]/best",
            "--merge-output-format", "mp4",
            "--no-warnings",
            "--no-check-certificates",
            "--force-ipv4",
            "--socket-timeout", "30",
            "--retries", "3",
            "-o", output_template,
            req.url,
        ]
    else:
        cmd = [
            "python3", "-m", "yt_dlp",
            "--no-playlist",
            "-x",
            "--audio-format", "mp3",
            "--audio-quality", "0",
            "--no-warnings",
            "--no-check-certificates",
            "--force-ipv4",
            "--socket-timeout", "30",
            "--retries", "3",
            "-o", output_template,
            req.url,
        ]

    output_path = None

    try:
        # Set environment to use Google DNS as fallback
        env = os.environ.copy()
        env["PYTHONDONTWRITEBYTECODE"] = "1"

        # Run yt-dlp
        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            env=env,
        )
        try:
            stdout, stderr = await asyncio.wait_for(proc.communicate(), timeout=240)
        except asyncio.TimeoutError:
            proc.kill()
            raise HTTPException(status_code=504, detail="Download timed out")

        # Handle errors
        if proc.returncode != 0:
            stderr_text = stderr.decode(errors="replace") if stderr else ""
            stdout_text = stdout.decode(errors="replace") if stdout else ""
            all_output = stderr_text + stdout_text

            if "Video unavailable" in all_output:
                raise HTTPException(status_code=410, detail="This video is unavailable or private")
            if "Sign in" in all_output or "login" in all_output:
                raise HTTPException(status_code=403, detail="This content requires authentication")
            if "429" in all_output:
                raise HTTPException(status_code=429, detail="Rate limited. Please try again later.")
            if "No address associated" in all_output or "Errno -5" in all_output:
                raise HTTPException(status_code=503, detail="DNS resolution failed. The server cannot reach external sites right now. Please try again in a few minutes.")
            if "Unable to download" in all_output:
                raise HTTPException(status_code=502, detail=f"Could not reach video host: {stderr_text[:200]}")
            raise HTTPException(status_code=500, detail=f"Download failed: {stderr_text[:200]}")

        # Find the output file
        matches = glob.glob(f"{TMP_DIR}/{job_id}.*")
        if not matches:
            raise HTTPException(status_code=500, detail="Download produced no output file")

        output_path = matches[0]
        actual_ext = os.path.splitext(output_path)[1].lstrip(".")

        # Read file bytes
        with open(output_path, "rb") as f:
            file_bytes = f.read()

        return Response(
            content=file_bytes,
            media_type="application/octet-stream",
            headers={
                "Content-Disposition": f"attachment; filename=media.{actual_ext}"
            },
        )
    finally:
        # Always clean up
        if output_path and os.path.exists(output_path):
            try:
                os.remove(output_path)
            except OSError:
                pass
