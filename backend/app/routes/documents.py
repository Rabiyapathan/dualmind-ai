from pathlib import Path
from uuid import uuid4

import fitz
from flask import Blueprint, current_app, jsonify, request
from werkzeug.utils import secure_filename

from app.services.pdf_service import extract_pdf_pages, chunk_pages

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

    upload_dir = Path(current_app.config["UPLOAD_FOLDER"])
    upload_dir.mkdir(parents=True, exist_ok=True)

    file_path = upload_dir / f"{uuid4().hex}.pdf"

    try:
        uploaded_file.save(file_path)

        pages = extract_pdf_pages(str(file_path))
        chunks = chunk_pages(pages)

        if not chunks:
            return jsonify({
                "error": "No extractable text found. Scanned PDFs need OCR."
            }), 422

        return jsonify({
            "message": "PDF processed successfully.",
            "document_id": file_path.stem,
            "filename": safe_name,
            "page_count": len(pages),
            "chunk_count": len(chunks),
            "chunks": chunks,
        }), 200

    except (ValueError, fitz.FileDataError):
        current_app.logger.warning("Invalid PDF upload")
        return jsonify({
            "error": "The uploaded PDF is invalid or unsupported."
        }), 400

    except Exception:
        current_app.logger.exception("PDF processing failed")
        return jsonify({"error": "PDF processing failed."}), 500

    finally:
        # Keep the original PDF for future indexing.
        # It is stored under a unique generated filename.
        pass
