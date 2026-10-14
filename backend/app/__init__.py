from pathlib import Path

from flask import Flask, jsonify
from flask_cors import CORS

from app.routes.documents import documents_bp


def create_app():
    app = Flask(__name__)

    app.config["MAX_CONTENT_LENGTH"] = 20 * 1024 * 1024
    app.config["UPLOAD_FOLDER"] = str(
        Path(__file__).resolve().parent.parent / "data" / "uploads"
    )

    CORS(app)
    app.register_blueprint(documents_bp)

    @app.get("/health")
    def health():
        return jsonify({
            "status": "healthy",
            "project": "DualMind AI",
            "message": "Backend is running"
        }), 200

    return app
