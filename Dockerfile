FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# Systempakete
RUN apt-get update && apt-get install -y \
    git ffmpeg python3-pip python3-dev build-essential \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Repo holen
RUN git clone https://github.com/Wan-Video/Wan2.2.git

# 1) PyTorch (passt zu CUDA 12.1)
RUN pip3 install --no-cache-dir --extra-index-url https://download.pytorch.org/whl/cu121 \
    torch==2.4.0 torchvision==0.19.0

# 2) Restliche Requirements (ohne triton/xformers)
RUN grep -vE "triton|xformers" /workspace/Wan2.2/requirements.txt > /workspace/req_clean.txt \
 && pip3 install --no-cache-dir -r /workspace/req_clean.txt

# 3) RunPod-Wrapper
RUN pip3 install --no-cache-dir runpod

# Modelle liegen später in /models (RunPod-Volume)
ENV WAN_CKPT_DIR=/models/Wan2.2-TI2V-5B

# Dein Handler
COPY handler.py /workspace/handler.py

# Serverless-API starten
CMD ["python3","/workspace/handler.py","--rp_serve_api","--rp_api_host","0.0.0.0","--rp_api_port","8000"]
