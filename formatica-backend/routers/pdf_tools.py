from fastapi import APIRouter, UploadFile, Form, HTTPException, File
from fastapi.responses import Response
from pypdf import PdfWriter, PdfReader
import io

router = APIRouter()

@router.post("/merge")
async def merge_pdfs(files: list[UploadFile] = File(...)):
    if len(files)<2: raise HTTPException(400,"Need at least 2 PDFs")
    writer = PdfWriter()
    for f in files:
        reader = PdfReader(io.BytesIO(await f.read()))
        for page in reader.pages: writer.add_page(page)
    buf = io.BytesIO()
    writer.write(buf)
    return Response(content=buf.getvalue(),media_type="application/octet-stream",
        headers={"Content-Disposition":"attachment; filename=merged.pdf"})

@router.post("/split")
async def split_pdf(file: UploadFile,
    start_page: int = Form(1), end_page: int = Form(0)):
    reader = PdfReader(io.BytesIO(await file.read()))
    total = len(reader.pages)
    start = max(0, start_page-1)
    end = min(total, end_page if end_page>0 else total)
    if start>=end: raise HTTPException(400,f"Invalid range. PDF has {total} pages.")
    writer = PdfWriter()
    for i in range(start,end): writer.add_page(reader.pages[i])
    buf = io.BytesIO()
    writer.write(buf)
    return Response(content=buf.getvalue(),media_type="application/octet-stream",
        headers={"Content-Disposition":"attachment; filename=split.pdf"})

@router.post("/greyscale")
async def greyscale_pdf(file: UploadFile):
    """Convert PDF to greyscale using PyPDF + PIL for image XObjects."""
    from PIL import Image
    import os, uuid, glob, subprocess

    data = await file.read()
    job_id = uuid.uuid4().hex
    input_path = f"/app/tmp/{job_id}_input.pdf"
    img_prefix = f"/app/tmp/{job_id}_page"

    try:
        # Write input PDF
        with open(input_path, "wb") as f:
            f.write(data)

        # Render PDF pages to PNG images using pdftoppm
        proc = subprocess.run(
            ["pdftoppm", "-png", "-r", "200", input_path, img_prefix],
            capture_output=True, timeout=120
        )

        if proc.returncode != 0:
            stderr_msg = proc.stderr.decode()[-200:]
            print(f"pdftoppm failed: {stderr_msg}")
            raise HTTPException(500, "Failed to process PDF for greyscale conversion")

        # pdftoppm outputs files like: prefix-1.png, prefix-2.png, prefix-01.png etc
        page_images = sorted(glob.glob(f"{img_prefix}-*.png") + glob.glob(f"{img_prefix}*.png"))
        # Deduplicate
        page_images = sorted(set(page_images))

        if not page_images:
            raise HTTPException(500, "Failed to render PDF pages")

        # Convert each page image to greyscale
        grey_images = []
        for img_path in page_images:
            img = Image.open(img_path).convert("L").convert("RGB")
            grey_images.append(img)

        # Save all grey images as a single PDF
        buf = io.BytesIO()
        if len(grey_images) == 1:
            grey_images[0].save(buf, format="PDF", resolution=200)
        else:
            grey_images[0].save(buf, format="PDF", save_all=True,
                append_images=grey_images[1:], resolution=200)

        return Response(content=buf.getvalue(), media_type="application/octet-stream",
            headers={"Content-Disposition": "attachment; filename=greyscale.pdf"})

    except HTTPException:
        raise
    except Exception as e:
        print(f"Greyscale error: {e}")
        raise HTTPException(500, f"Greyscale conversion failed: {str(e)}")
    finally:
        # Cleanup - remove input file and all generated page images
        try:
            os.remove(input_path)
        except OSError:
            pass
        for img_file in glob.glob(f"{img_prefix}*.png"):
            try:
                os.remove(img_file)
            except OSError:
                pass
