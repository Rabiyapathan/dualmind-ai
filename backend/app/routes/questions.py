
from flask import Blueprint, current_app, jsonify, request

from ..services.document_store import DocumentStore
from ..services.retrieval_service import RetrievalService

from ..services.qa_service import QAService

questions_bp = Blueprint("questions", __name__)


@questions_bp.post("/documents/<document_id>/search")
def search_document(document_id):
    data = request.get_json(silent=True)

    if not isinstance(data, dict):
        return jsonify({"error": "Send a JSON request body."}), 400

    question = data.get("question")
    if not isinstance(question, str) or not question.strip():
        return jsonify({"error": "A question is required."}), 400

    top_k = data.get("top_k", 3)
    if isinstance(top_k, bool) or not isinstance(top_k, int) or top_k < 1:
        return jsonify({"error": "top_k must be a positive integer."}), 400

    store = DocumentStore(current_app.config["INDEX_FOLDER"])

    try:
        index, chunks = store.load(document_id)
    except FileNotFoundError:
        return jsonify({"error": "Document index not found."}), 404
    except ValueError:
        return jsonify({"error": "Invalid document ID."}), 400

    try:
        retrieval = RetrievalService()
        results = retrieval.search(
            question=question.strip(),
            top_k=top_k,
            index=index,
            chunks=chunks,
        )
    except ValueError as exc:
        return jsonify({"error": str(exc)}), 400

    return jsonify({
        "document_id": document_id,
        "question": question.strip(),
        "results": results,
        "result_count": len(results),
    }), 200


@questions_bp.post("/documents/<document_id>/ask")
def ask_document(document_id):
    data = request.get_json(silent=True)

    if not isinstance(data, dict):
        return jsonify({"error": "Send a JSON request body."}), 400

    question = data.get("question")
    if not isinstance(question, str) or not question.strip():
        return jsonify({"error": "A question is required."}), 400

    top_k = data.get("top_k", 3)
    if isinstance(top_k, bool) or not isinstance(top_k, int) or top_k < 1:
        return jsonify({"error": "top_k must be a positive integer."}), 400

    store = DocumentStore(current_app.config["INDEX_FOLDER"])

    try:
        index, chunks = store.load(document_id)
    except FileNotFoundError:
        return jsonify({"error": "Document index not found."}), 404
    except ValueError:
        return jsonify({"error": "Invalid document ID."}), 400

    try:
        retrieval = RetrievalService()
        passages = retrieval.search(
            question=question.strip(),
            top_k=top_k,
            index=index,
            chunks=chunks,
        )

        answer = QAService().answer(question.strip(), passages)

        return jsonify({
            "document_id": document_id,
            "question": question.strip(),
            "answer": answer,
            "sources": [
                {"page": passage["page"], "text": passage["text"]}
                for passage in passages
            ],
        }), 200

    except Exception:
        current_app.logger.exception("Document question answering failed")
        return jsonify({
            "error": "Could not generate an answer. Check the server logs."
        }), 502

