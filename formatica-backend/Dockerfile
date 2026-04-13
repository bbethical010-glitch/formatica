FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libreoffice \
    ffmpeg \
    libmagic1 \
    poppler-utils \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies (cached layer)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY . .

# Create temp directory with open permissions (HF Spaces may run as non-root)
RUN mkdir -p /app/tmp && chmod 777 /app/tmp

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV TMPDIR=/app/tmp
ENV HOME=/app

EXPOSE 7860

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]
