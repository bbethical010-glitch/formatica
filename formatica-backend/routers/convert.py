import os
import uuid
import glob
import asyncio
import tempfile
from pathlib import Path

import aiofiles
from fastapi import APIRouter, File, Form, UploadFile, HTTPException
from fastapi.responses import Response

from utils.validators import (
    SUPPORTED_INPUT_FORMATS,
    SUPPORTED_OUTPUT_FORMATS,
    is_safe_filename,
)

router = APIRouter()

TMP_DIR = Path(
    os.environ.get(
        "FORMATICA_TMP_DIR",
        os.path.join(tempfile.gettempdir(), "formatica-backend"),
    )
)
TMP_DIR.mkdir(parents=True, exist_ok=True)


@router.post("/")
async def convert_file(
    file: UploadFile = File(...),
    output_format: str = Form(...),
):
    # Validate original filename
    if not file.filename or not is_safe_filename(file.filename):
        raise HTTPException(status_code=400, detail="Invalid filename")

    # Extract and validate input extension
    input_ext = file.filename.rsplit(".", 1)[-1].lower() if "." in file.filename else ""
    if input_ext not in SUPPORTED_INPUT_FORMATS:
        raise HTTPException(status_code=400, detail="Unsupported input format")

    # Validate output format
    output_format = output_format.lower().strip()
    if input_ext not in SUPPORTED_OUTPUT_FORMATS or output_format not in SUPPORTED_OUTPUT_FORMATS[input_ext]:
        raise HTTPException(status_code=400, detail="Unsupported conversion path")

    # Generate unique job ID and file paths
    job_id = uuid.uuid4().hex
    input_filename = f"{job_id}_input.{input_ext}"
    input_path = TMP_DIR / input_filename
    input_stem = input_path.stem  # e.g. "abc123_input"
    output_path = None

    try:
        # Save uploaded file
        async with aiofiles.open(input_path, "wb") as f:
            content = await file.read()
            await f.write(content)

        # Run LibreOffice conversion
        proc = await asyncio.create_subprocess_exec(
            "soffice", "--headless",
            "--convert-to", output_format,
            "--outdir", str(TMP_DIR),
            str(input_path),
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        try:
            await asyncio.wait_for(proc.communicate(), timeout=60)
        except asyncio.TimeoutError:
            proc.kill()
            raise HTTPException(status_code=504, detail="Conversion timed out")

        # Find the output file — soffice names it based on input stem
        pattern = str(TMP_DIR / f"{input_stem}.{output_format}")
        matches = glob.glob(pattern)
        if not matches:
            raise HTTPException(status_code=500, detail="Conversion produced no output")

        output_path = Path(matches[0])

        # Read output file bytes
        async with aiofiles.open(output_path, "rb") as f:
            output_bytes = await f.read()

        return Response(
            content=output_bytes,
            media_type="application/octet-stream",
            headers={
                "Content-Disposition": f"attachment; filename=converted.{output_format}"
            },
        )
    finally:
        # Always clean up temp files
        for path in [input_path, output_path]:
            if path and Path(path).exists():
                try:
                    Path(path).unlink()
                except OSError:
                    pass
