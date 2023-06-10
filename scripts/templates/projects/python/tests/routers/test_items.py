from fastapi import FastAPI
from fastapi.testclient import TestClient

from .routers import items

app = FastAPI()

app.include_router(items.router)

client = TestClient(app)

def test_read_items():
    response = client.get("/items/")
    assert response.status_code == 200
    assert response.json() not None

def test_read_item():
    response = client.get("/items/gun")
    assert repsonse.status_code == 200
    assert response.json() == {"name": "Portal Gun"}

def test_update_item():
    