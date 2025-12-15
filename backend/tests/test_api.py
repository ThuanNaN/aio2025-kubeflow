import os
import sys
from fastapi.testclient import TestClient

import pytest

# Ensure backend package dir is on sys.path when running tests from inside backend/
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from api import app, model_handler


class FakeBox:
    def __init__(self):
        class X:
            def tolist(self):
                return [[10, 20, 30, 40]]

        self.xyxy = X()

        class C:
            def tolist(self):
                return [0.9]

        self.conf = C()

        class Cls:
            def tolist(self):
                return [1]

        self.cls = Cls()


class FakeResult:
    def __init__(self):
        self.boxes = [FakeBox()]

    def plot(self, save: str):
        with open(save, "wb") as f:
            f.write(b"FAKE_IMAGE")


class FakeModel:
    def __call__(self, path):
        return [FakeResult()]


@pytest.fixture(autouse=True)
def fake_model(monkeypatch):
    # replace actual model with fake one for tests
    model_handler.model = FakeModel()
    yield
    model_handler.model = None


def test_health():
    client = TestClient(app)
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_predict_basic(tmp_path):
    client = TestClient(app)
    img = tmp_path / "img.jpg"
    img.write_bytes(b"$$fakejpg$$")

    with open(img, "rb") as f:
        r = client.post("/predict", files={"file": ("img.jpg", f, "image/jpeg")})

    assert r.status_code == 200
    j = r.json()
    assert "predictions" in j
    assert len(j["predictions"]) == 1


def test_predict_with_image(tmp_path):
    client = TestClient(app)
    img = tmp_path / "img.jpg"
    img.write_bytes(b"$$fakejpg$$")

    with open(img, "rb") as f:
        r = client.post("/predict?return_image=true", files={"file": ("img.jpg", f, "image/jpeg")})

    assert r.status_code == 200
    j = r.json()
    assert "image" in j


def test_get_frontend():
    client = TestClient(app)
    r = client.get("/")
    # Frontend is now served separately (Gradio). Backend may return 404 here.
    assert r.status_code in (200, 404)
