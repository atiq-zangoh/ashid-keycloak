import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.db.database import Base, get_db
from app.core.config import settings

# Create test database
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base.metadata.create_all(bind=engine)


def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)


@pytest.fixture
def test_user():
    return {
        "email": "test@example.com",
        "username": "testuser",
        "password": "Test1234!",
        "full_name": "Test User"
    }


def test_root():
    response = client.get("/")
    assert response.status_code == 200
    assert "message" in response.json()


def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_register_user(test_user):
    response = client.post(f"{settings.API_V1_PREFIX}/auth/register", json=test_user)
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == test_user["email"]
    assert data["username"] == test_user["username"]
    assert "id" in data


def test_login_user(test_user):
    # First register the user
    client.post(f"{settings.API_V1_PREFIX}/auth/register", json=test_user)
    
    # Then login
    response = client.post(
        f"{settings.API_V1_PREFIX}/auth/token",
        data={
            "username": test_user["username"],
            "password": test_user["password"]
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"


def test_get_current_user(test_user):
    # Register and login
    client.post(f"{settings.API_V1_PREFIX}/auth/register", json=test_user)
    login_response = client.post(
        f"{settings.API_V1_PREFIX}/auth/token",
        data={
            "username": test_user["username"],
            "password": test_user["password"]
        }
    )
    token = login_response.json()["access_token"]
    
    # Get current user
    response = client.get(
        f"{settings.API_V1_PREFIX}/users/me",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == test_user["email"]
    assert data["username"] == test_user["username"]
