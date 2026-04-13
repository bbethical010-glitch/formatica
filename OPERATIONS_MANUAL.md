# Formatica: Operations Manual

Formatica is a privacy-first, all-in-one media processing suite designed to handle your documents, videos, and images entirely on your local machine. This manual details every operation available in the current version.

---

## 1. Document Operations

### 📄 Convert Document
Transform document files between various professional formats.
- **Supported Inputs**: .docx, .pdf, .xlsx, .csv, .txt, .odt, .rtf, .pptx
- **Supported Outputs**: .pdf, .docx, .odt, .txt, .html, .rtf, .xlsx, .csv
- **Requirement**: Requires **LibreOffice** (v7.0+) to be installed.

### 🔗 Merge PDF
Combine multiple PDF documents into a single, cohesive file.
- **Action**: Drag and drop multiple PDFs to reorder and merge.

### ✂️ Split PDF
Divide a single PDF into multiple smaller files.
- **Options**: Split by page ranges (e.g., 1-5, 10-12) or extract individual pages.

### 🎨 Greyscale PDF
Convert colored PDFs into high-quality black and white versions.
- **Utility**: Significantly reduces printing costs and file size.

---

## 2. Media Operations

### ⬇️ Download Media
Save online content for offline viewing.
- **Features**: Supports high-quality video and audio extraction from popular online platforms.
- **Requirement**: Powered by the **yt-dlp** engine (managed automatically by the app).

### 🎵 Extract Audio
Strip the audio track from any video file.
- **Output Formats**: .mp3, .aac, .wav
- **Quality**: Preserves original bitrates where possible.

### 🎬 Convert Video
Transcode videos between modern formats for better compatibility.
- **Supported Formats**: .mp4, .mkv, .mov, .avi, .webm

### 🗜️ Compress Video
Significantly reduce video file sizes while maintaining visual fidelity.
- **Hardware Acceleration**: Automatically uses your GPU (NVIDIA/AMD/Apple) for 5-10x faster processing.
- **Utility**: Ideal for preparing videos for email or Discord.

---

## 3. Image Operations

### 🖼️ Images to PDF
The fastest way to create a digital document from scans or photos.
- **Action**: Combine multiple image files (JPG, PNG, WEBP, etc.) into a single, paginated PDF.

### 🔄 Convert Image
Switch between image formats for web or print optimization.
- **Supported Formats**: .jpg, .png, .webp, .gif, .bmp

---

## 4. System & Privacy Features

### 🛡️ Local-Only Processing
- **Privacy**: Formatica never uploads your files to a server. All processing (OCR, Conversion, Compression) happens on your CPU/GPU.
- **Security**: Works entirely offline once dependencies are installed.

### ⚡ Dependency Management
- **Setup Status**: The app automatically checks for required tools (yt-dlp, LibreOffice, Python, Tesseract) on startup.
- **Auto-Fix**: One-click "Fix Now" button to download and configure missing dependencies.

### 🌓 Personalization
- **Theme Engine**: Seamless switching between high-contrast **Dark Mode** and clean **Light Mode**.
- **Activity Log**: Keeps a secure, local history of your 10 most recent operations for quick reference.

---

## Technical Requirements
- **macOS**: Apple Silicon (M1/M2/M3) or Intel processor.
- **Windows**: Windows 10/11 (x64).
- **Disk Space**: ~500MB for the app, plus extra for dependencies (LibreOffice).
