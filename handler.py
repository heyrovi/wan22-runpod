import os, subprocess, shlex, glob, runpod, json

REPO="/workspace/Wan2.2"
CKPT=os.environ.get("WAN_CKPT_DIR","/models/Wan2.2-TI2V-5B")
OUT="/tmp/out.mp4"

def sh(cmd:str):
    print(">>", cmd, flush=True)
    subprocess.check_call(cmd, shell=True)

def ensure_models():
    if not os.path.exists(CKPT) or not os.listdir(CKPT):
        hf=os.environ.get("HF_TOKEN","")
        auth=f"--token {shlex.quote(hf)}" if hf else ""
        sh(f"pip install -q 'huggingface_hub[cli]'")
        sh(f"huggingface-cli download Wan-AI/Wan2.2-TI2V-5B --local-dir {shlex.quote(CKPT)} {auth}")

def generate(prompt:str, seconds:int=5, size:str="1280*720"):
    sh(f"python {REPO}/generate.py --task ti2v-5B --size {size} "
       f"--ckpt_dir {shlex.quote(CKPT)} --convert_model_dtype --offload_model True "
       f"--prompt {shlex.quote(prompt)} --seconds {int(seconds)}")
    mp4s=[p for p in glob.glob('**/*.mp4', recursive=True)]
    mp4=max(mp4s, key=os.path.getmtime)
    sh(f'ffmpeg -y -i "{mp4}" -c:v libx264 -pix_fmt yuv420p "{OUT}"')
    return OUT

def upscale_1080p(src:str, crf:int=18):
    dst="/tmp/out_1080p.mp4"
    sh(f'ffmpeg -y -i "{src}" -vf scale=1920:1080:flags=lanczos -c:v libx264 -crf {crf} -pix_fmt yuv420p "{dst}"')
    return dst

def handler(event):
    inp=event.get("input",{})
    prompt=inp.get("prompt","a cinematic drone shot over mountains")
    seconds=int(inp.get("seconds",5))
    size=inp.get("size","1280*720")
    want1080=bool(inp.get("upscale_1080p", True))
    ensure_models()
    path=generate(prompt, seconds, size)
    if want1080:
        path=upscale_1080p(path, crf=int(inp.get("crf",18)))
    return {"video_path": path, "seconds": seconds, "size": size}

runpod.serverless.start({"handler": handler})
