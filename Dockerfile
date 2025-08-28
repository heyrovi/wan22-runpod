FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

RUN apt-get update && apt-get install -y git ffmpeg python3-pip && rm -rf /var/lib/apt/lists/*
WORKDIR /workspace

# Wan2.2 holen
RUN git clone https://github.com/Wan-Video/Wan2.2.git
# PyTorch + Abhängigkeiten
RUN pip3 install --no-cache-dir torch==2.4.0 --index-url https://download.pytorch.org/whl/cu121
RUN pip3 install --no-cache-dir -r /workspace/Wan2.2/requirements.txt runpod

# Modelle liegen auf /models (Volume in RunPod)
ENV WAN_CKPT_DIR=/models/Wan2.2-TI2V-5B
COPY handler.py /workspace/handler.py

# RunPod-Serverless API
CMD ["python3","/workspace/handler.py","--rp_serve_api","--rp_api_host","0.0.0.0","--rp_api_port","8000"]
