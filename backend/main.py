import os
import uvicorn

from api import app


if __name__ == "__main__":
    host = os.environ.get("HOST", "0.0.0.0")
    port = int(os.environ.get("PORT", "8000"))
    uvicorn.run("api:app", host=host, port=port, reload=True)
