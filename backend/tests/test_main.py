"""
Smoke tests — kiểm tra API có sống không.
Đây là bài test khởi đầu cho dự án. Các thành viên bổ sung thêm test sau.
"""


def test_health_returns_200(client):
    """GET /health phải trả về 200 OK và status 'ok'."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "version" in data
