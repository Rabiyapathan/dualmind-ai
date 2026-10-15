
import numpy as np
import pytest
import faiss

from app.services.document_store import DocumentStore


def test_save_and_load_document_index(tmp_path):
    store = DocumentStore(str(tmp_path))

    index = faiss.IndexFlatIP(2)
    vectors = np.array([[1.0, 0.0], [0.0, 1.0]], dtype=np.float32)
    index.add(vectors)

    chunks = [
        {"page": 1, "text": "Python programming"},
        {"page": 3, "text": "Database connections"},
    ]

    store.save("document-123", index, chunks)

    loaded_index, loaded_chunks = store.load("document-123")

    assert loaded_index.ntotal == 2
    assert loaded_chunks == chunks


def test_missing_document_raises_error(tmp_path):
    store = DocumentStore(str(tmp_path))

    with pytest.raises(FileNotFoundError):
        store.load("missing-document")


def test_invalid_document_id_is_rejected(tmp_path):
    store = DocumentStore(str(tmp_path))

    with pytest.raises(ValueError):
        store.load("../outside")
