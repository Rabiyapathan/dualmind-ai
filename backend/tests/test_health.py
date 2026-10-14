from app import create_app


def test_health_endpoint():
    app = create_app()
    app.config["TESTING"] = True

    client = app.test_client()
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json["status"] == "healthy"
    assert response.json["project"] == "DualMind AI"
