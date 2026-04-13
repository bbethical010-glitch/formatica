from fastapi import APIRouter, UploadFile, Form, HTTPException
from fastapi.responses import Response
import asyncio, uuid, os, aiofiles

router = APIRouter()

@router.post("/convert")
async def convert_video(file: UploadFile, output_format: str = Form(...)):
    allowed_in = {"mp4","mkv","avi","mov","webm","flv","m4v"}
    allowed_out = {"mp4","mkv","avi","mov","webm","gif"}
    ext = file.filename.split(".")[-1].lower()
    if ext not in allowed_in: raise HTTPException(400,"Unsupported input")
    if output_format not in allowed_out: raise HTTPException(400,"Unsupported output")
    job = uuid.uuid4().hex
    inp = f"/app/tmp/{job}_in.{ext}"
    out = f"/app/tmp/{job}_out.{output_format}"
    try:
        async with aiofiles.open(inp,"wb") as f: await f.write(await file.read())

        if output_format == "gif":
            palette = f"/app/tmp/{job}_palette.png"
            p1 = await asyncio.create_subprocess_exec(
                "ffmpeg", "-i", inp,
                "-vf", "fps=12,scale=480:-1:flags=lanczos,palettegen=stats_mode=diff",
                "-y", palette,
                stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
            await asyncio.wait_for(p1.communicate(), timeout=120)
            p2 = await asyncio.create_subprocess_exec(
                "ffmpeg", "-i", inp, "-i", palette,
                "-lavfi", "fps=12,scale=480:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5",
                "-y", out,
                stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
            try: await asyncio.wait_for(p2.communicate(), timeout=300)
            except asyncio.TimeoutError: p2.kill(); raise HTTPException(504,"Timeout")
            if p2.returncode != 0: raise HTTPException(500,"GIF conversion failed")
            try: os.remove(palette)
            except: pass
        else:
            cmd = ["ffmpeg", "-i", inp]
            # For webm output use VP9, otherwise use H.264
            if output_format == "webm":
                cmd += ["-c:v", "libvpx-vp9", "-b:v", "0", "-crf", "30", "-c:a", "libopus"]
            else:
                cmd += ["-c:v", "libx264", "-c:a", "aac"]
            cmd += ["-y", out]
            proc = await asyncio.create_subprocess_exec(*cmd,
                stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
            try:
                _, stderr = await asyncio.wait_for(proc.communicate(), timeout=300)
            except asyncio.TimeoutError:
                proc.kill()
                raise HTTPException(504, "Timeout")
            if proc.returncode != 0:
                print(f"Convert error: {stderr.decode()[-300:]}")
                raise HTTPException(500, "Conversion failed")

        async with aiofiles.open(out,"rb") as f: data=await f.read()
        return Response(content=data, media_type="application/octet-stream",
            headers={"Content-Disposition":f"attachment; filename=converted.{output_format}"})
    finally:
        for p in [inp, out]:
            try: os.remove(p)
            except: pass

@router.post("/compress")
async def compress_video(file: UploadFile, crf: int = Form(23),
    preset: str = Form("medium"), resolution: str = Form("")):
    """High-quality video compression preserving colors and details."""
    allowed_in = {"mp4","mkv","avi","mov","webm","flv","m4v"}
    ext = file.filename.split(".")[-1].lower()
    if ext not in allowed_in: raise HTTPException(400, "Unsupported input")
    if not 18 <= crf <= 51: crf = 23
    if preset not in {"ultrafast","superfast","veryfast","faster","fast","medium","slow","slower","veryslow"}:
        preset = "medium"
    job = uuid.uuid4().hex
    inp = f"/app/tmp/{job}_in.{ext}"
    out = f"/app/tmp/{job}_compressed.mp4"
    try:
        async with aiofiles.open(inp, "wb") as f: await f.write(await file.read())

        # Build ffmpeg command — scale filter goes inside -vf, not as separate flags
        vf_parts = []
        if resolution and resolution != "original":
            # lanczos scaling inside the filter chain
            vf_parts.append(f"scale={resolution}:flags=lanczos")

        cmd = ["ffmpeg", "-i", inp]
        if vf_parts:
            cmd += ["-vf", ",".join(vf_parts)]

        cmd += [
            "-c:v", "libx264",
            "-crf", str(crf),
            "-preset", preset,
            "-profile:v", "high",
            "-pix_fmt", "yuv420p",
            "-colorspace", "bt709",
            "-color_primaries", "bt709",
            "-color_trc", "bt709",
            "-c:a", "aac",
            "-b:a", "192k",
            "-movflags", "+faststart",
            "-y", out
        ]

        proc = await asyncio.create_subprocess_exec(*cmd,
            stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
        try:
            _, stderr = await asyncio.wait_for(proc.communicate(), timeout=600)
        except asyncio.TimeoutError:
            proc.kill()
            raise HTTPException(504, "Compression timed out")

        if proc.returncode != 0:
            err = stderr.decode()[-500:]
            print(f"Compress error: {err}")
            raise HTTPException(500, f"Compression failed")

        async with aiofiles.open(out, "rb") as f: data = await f.read()
        return Response(content=data, media_type="application/octet-stream",
            headers={"Content-Disposition": "attachment; filename=compressed.mp4"})
    finally:
        for p in [inp, out]:
            try: os.remove(p)
            except: pass
