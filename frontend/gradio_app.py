import io
import os
import requests
from PIL import Image
import gradio as gr


BACKEND_URL = os.environ.get("BACKEND_URL", "http://localhost:8000/predict")


def run_inference(image, return_image=False):
    if image is None:
        return "No image provided", None

    # Gradio gives us a PIL Image or numpy array; convert to bytes
    img_byte_arr = io.BytesIO()
    if isinstance(image, Image.Image):
        image.save(img_byte_arr, format='JPEG')
    else:
        Image.fromarray(image).save(img_byte_arr, format='JPEG')

    img_byte_arr.seek(0)

    params = {}
    if return_image:
        params['return_image'] = 'true'

    files = {'file': ('image.jpg', img_byte_arr, 'image/jpeg')}

    try:
        resp = requests.post(BACKEND_URL, params=params, files=files, timeout=30)
        resp.raise_for_status()
    except Exception as e:
        return f"Request failed: {e}", None

    j = resp.json()

    annotated = None
    if j.get('image'):
        image_data = io.BytesIO()
        image_data.write(bytes(j['image'], 'utf-8'))
        # it's base64 string; decode
        import base64
        annotated = Image.open(io.BytesIO(base64.b64decode(j['image'])))

    pretty = j
    return pretty, annotated


def launch(interface_port: int = 7860):
    with gr.Blocks() as demo:
        gr.Markdown("# YOLO11n Gradio Demo")
        with gr.Row():
            img_in = gr.Image(type='pil', label='Input Image')
            with gr.Column():
                ret_img = gr.Checkbox(label='Return annotated image', value=True)
                btn = gr.Button('Run')
        out_text = gr.JSON(label='Predictions')
        out_img = gr.Image(label='Annotated image')

        def _run(img, return_image):
            return run_inference(img, return_image)

        btn.click(fn=_run, inputs=[img_in, ret_img], outputs=[out_text, out_img])

    demo.launch(server_name='0.0.0.0', server_port=interface_port)


if __name__ == '__main__':
    port = int(os.environ.get('GRADIO_PORT', 7860))
    launch(port)
