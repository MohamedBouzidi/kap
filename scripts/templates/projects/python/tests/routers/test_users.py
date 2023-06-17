from fastapi import FastAPI
from fastapi.testclient import TestClient

from routers import users

app = FastAPI()
app.include_router(users.router)
client = TestClient(app)


def test_read_users():
    response = client.get("/users/")
    assert response.status_code == 200
    assert response.json() is not None


def test_read_user_me():
    response = client.get("/users/me")
    assert response.status_code == 200
    assert response.json() == {"username": "fakecurrentuser"}


def test_read_user():
    response = client.get("/users/joe")
    assert response.status_code == 200
    assert response.json() == {"username": "joe"}
