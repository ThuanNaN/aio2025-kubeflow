from fastapi import FastAPI, UploadFile, File, HTTPException, Query
from fastapi.responses import JSONResponse
from typing import Optional
import tempfile
import shutil
import os
import base64
import io
from PIL import Image
import numpy as np
from fastapi.staticfiles import StaticFiles

app = FastAPI(title="YOLO11n Inference API")


class ModelHandler:
    """Lazy loader for the underlying YOLO model."""

    def __init__(self, model_path: Optional[str] = None):
        self.model = None
        self.model_path = model_path or os.environ.get("YOLO_MODEL", "yolo11n.pt")

    def load(self):
        if self.model is None:
            try:
                from ultralytics import YOLO
            except Exception as e:
                raise RuntimeError("ultralytics package is required for inference: pip install ultralytics") from e

            # load model (this may download or load from a local path)
            self.model = YOLO(self.model_path)
        return self.model


model_handler = ModelHandler()


def _save_upload_to_temp(upload: UploadFile) -> str:
    suffix = os.path.splitext(upload.filename)[1] or ".jpg"
    fd, tmp_path = tempfile.mkstemp(suffix=suffix)
    os.close(fd)
    with open(tmp_path, "wb") as out:
        shutil.copyfileobj(upload.file, out)
    return tmp_path


def _preds_to_json(results) -> dict:
    # results is from ultralytics YOLO inference
    out = {"predictions": []}
    for r in results:
        boxes = r.boxes
        if boxes is None:
            continue
        for b in boxes:
            xyxy = b.xyxy.tolist()[0]
            score = float(b.conf.tolist()[0]) if hasattr(b, "conf") else float(b.conf[0])
            cls = int(b.cls.tolist()[0]) if hasattr(b, "cls") else int(b.cls[0])
            out["predictions"].append({
                "xyxy": [float(x) for x in xyxy],
                "score": score,
                "class": cls,
            })
    return out


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/predict")
async def predict(file: UploadFile = File(...), return_image: bool = Query(False)):
    """Run YOLO inference on an uploaded image.

    - `file`: image file upload
    - `return_image`: if true, returns annotated image as base64 in `image` field
    """
    tmp_path = None
    try:
        tmp_path = _save_upload_to_temp(file)
        model = model_handler.load()
        # run inference
        results = model(tmp_path)

        payload = _preds_to_json(results)

        if return_image:
            # try to get annotated image from results.plot() (returns ndarray)
            try:
                annotated_path = tmp_path + ".annotated.jpg"
                annotated_arr = results[0].plot()
                if annotated_arr is not None:
                    # plot may return BGR image (opencv style); convert to RGB
                    if isinstance(annotated_arr, np.ndarray) and annotated_arr.ndim == 3 and annotated_arr.shape[2] == 3:
                        # convert BGR -> RGB
                        annotated_arr = annotated_arr[:, :, ::-1]
                    img = Image.fromarray(annotated_arr.astype('uint8'))
                    buf = io.BytesIO()
                    img.save(buf, format='JPEG')
                    data = base64.b64encode(buf.getvalue()).decode('ascii')
                    payload['image'] = data
                else:
                    # fallback: attempt to save to file then read
                    results[0].plot(save=annotated_path)
                    if os.path.exists(annotated_path):
                        with open(annotated_path, 'rb') as f:
                            data = base64.b64encode(f.read()).decode('ascii')
                        payload['image'] = data
            except Exception:
                # don't fail the whole request if image annotation fails
                pass

        return JSONResponse(payload)
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        try:
            if tmp_path and os.path.exists(tmp_path):
                os.remove(tmp_path)
            if tmp_path and os.path.exists(tmp_path + ".annotated.jpg"):
                os.remove(tmp_path + ".annotated.jpg")
        except Exception:
            pass


# Note: static demo was moved to top-level `frontend/` using Gradio
# The frontend Gradio app runs separately and calls this API at /predict.
