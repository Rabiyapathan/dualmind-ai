
from pathlib import Path

from flask import Flask, jsonify
from flask_cors import CORS

from .routes.documents import documents_bp
from .routes.questions import questions_bp

def create_app():
    app = Flask(__name__)

    data_dir = Path(__file__).resolve().parent.parent / "data"

    app.config["MAX_CONTENT_LENGTH"] = 20 * 1024 * 1024
    app.config["UPLOAD_FOLDER"] = str(data_dir / "uploads")
    app.config["INDEX_FOLDER"] = str(data_dir / "indexes")

    CORS(app)
    app.register_blueprint(documents_bp)
    app.register_blueprint(questions_bp)

    @app.get("/health")
    def health():
        return jsonify({
            "status": "healthy",
            "project": "DualMind AI",
            "message": "Backend is running",
        }), 200

    return app
