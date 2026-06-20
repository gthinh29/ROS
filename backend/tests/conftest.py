"""
Shared fixtures for backend tests.
"""
import pytest
from fastapi.testclient import TestClient
from main import app


@pytest.fixture()
def client():
    """Provide a TestClient instance pointing at the FastAPI app."""
    with TestClient(app) as c:
        yield c
