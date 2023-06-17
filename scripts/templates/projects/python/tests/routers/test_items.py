from fastapi import FastAPI
from fastapi.testclient import TestClient

from routers import items

app = FastAPI()
app.include_router(items.router)
client = TestClient(app)


def test_read_items():
    response = client.get("/items/", headers={"X-Token": "fake-super-secret-token"})
    assert response.status_code == 200
    assert response.json() is not None


def test_read_item():
    response = client.get("/items/gun", headers={"X-Token": "fake-super-secret-token"})
    assert response.status_code == 200
    assert response.json() == {"item_id": "gun", "name": "Portal Gun"}


def test_update_item():
    response = client.put(
        "/items/not_plumbus", headers={"X-Token": "fake-super-secret-token"}
    )
    assert response.status_code == 403
    assert response.json() == {"detail": "You can only update the item: plumbus"}
