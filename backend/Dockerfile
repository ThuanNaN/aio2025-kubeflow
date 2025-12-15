FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# System deps needed for some imaging libraries and ultralytics
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/requirements.txt

RUN pip install --upgrade pip \
    && pip install --no-cache-dir -r /app/requirements.txt

COPY . /app

EXPOSE 8000

# Default model path (override with YOLO_MODEL env)
ENV YOLO_MODEL=/app/model/yolo11n.pt

CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8000"]
