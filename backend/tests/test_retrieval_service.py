
from app.services.retrieval_service import RetrievalService


def test_retrieval_finds_relevant_chunk():
    service = RetrievalService()

    chunks = [
        {
            "page": 1,
            "text": "Python is a programming language used for automation.",
        },
        {
            "page": 4,
            "text": "A database connection pool reuses database connections.",
        },
        {
            "page": 7,
            "text": "HTTP 500 indicates an internal server error.",
        },
    ]

    service.build_index(chunks)
    results = service.search("How can database connections be reused?", top_k=2)

    assert results
    assert results[0]["page"] == 4
    assert "connection pool" in results[0]["text"]


def test_empty_question_is_rejected():
    service = RetrievalService()
    service.build_index([{"page": 1, "text": "Example document text."}])

    try:
        service.search("   ")
    except ValueError:
        pass
    else:
        raise AssertionError("Empty questions must be rejected.")
