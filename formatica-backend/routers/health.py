import asyncio
from fastapi import APIRouter

router = APIRouter()


async def _check_command(*cmd: str) -> str:
    """Run a command and return 'ok' if exit code is 0, else 'missing'."""
    try:
        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        await proc.communicate()
        return "ok" if proc.returncode == 0 else "missing"
    except FileNotFoundError:
        return "missing"


@router.get("/")
async def health_check():
    libreoffice_status, ffmpeg_status, ytdlp_status = await asyncio.gather(
        _check_command("soffice", "--version"),
        _check_command("ffmpeg", "-version"),
        _check_command("yt-dlp", "--version"),
    )
    return {
        "status": "ok",
        "dependencies": {
            "libreoffice": libreoffice_status,
            "ffmpeg": ffmpeg_status,
            "yt_dlp": ytdlp_status,
        },
    }
