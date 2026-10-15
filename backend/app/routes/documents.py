
from pathlib import Path
from uuid import uuid4

import fitz
from flask import Blueprint, current_app, jsonify, request
from werkzeug.utils import secure_filename

from ..services.pdf_service import extract_pdf_pages, chunk_pages
from ..services.retrieval_service import RetrievalService
from ..services.document_store import DocumentStore

documents_bp = Blueprint("documents", __name__)


@documents_bp.post("/documents/upload")
def upload_document():
    uploaded_file = request.files.get("file")

    if uploaded_file is None or not uploaded_file.filename:
        return jsonify({"error": "Upload a PDF using the 'file' field."}), 400

    if not uploaded_file.filename.lower().endswith(".pdf"):
        return jsonify({"error": "Only PDF files are supported."}), 400

    if request.content_length and request.content_length > 20 * 1024 * 1024:
        return jsonify({"error": "Maximum upload size is 20 MB."}), 413

    safe_name = secure_filename(uploaded_file.filename)
    if not safe_name:
        return jsonify({"error": "Invalid filename."}), 400

    document_id = uuid4().hex
    upload_dir = Path(current_app.config["UPLOAD_FOLDER"])
    upload_dir.mkdir(parents=True, exist_ok=True)
    file_path = upload_dir / f"{document_id}.pdf"

    try:
        uploaded_file.save(file_path)

        pages = extract_pdf_pages(str(file_path))
        chunks = chunk_pages(pages)

        if not chunks:
            file_path.unlink(missing_ok=True)
            return jsonify({
                "error": "No extractable text found. Scanned PDFs need OCR."
            }), 422

        retrieval = RetrievalService()
        retrieval.build_index(chunks)

        store = DocumentStore(current_app.config["INDEX_FOLDER"])
        store.save(document_id, retrieval.index, retrieval.chunks)

        return jsonify({
            "message": "PDF indexed successfully.",
            "document_id": document_id,
            "filename": safe_name,
            "page_count": len(pages),
            "chunk_count": len(chunks),
        }), 200

    except (ValueError, fitz.FileDataError):
        file_path.unlink(missing_ok=True)
        current_app.logger.warning("Invalid PDF upload")
        return jsonify({
            "error": "The uploaded PDF is invalid or unsupported."
        }), 400

    except Exception:
        file_path.unlink(missing_ok=True)
        current_app.logger.exception("PDF indexing failed")
        return jsonify({"error": "PDF indexing failed."}), 500

