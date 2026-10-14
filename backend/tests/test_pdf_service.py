import fitz
import pytest

from app.services.pdf_service import extract_pdf_pages, chunk_pages


def test_extract_pdf_pages(tmp_path):
    pdf_path = tmp_path / "sample.pdf"

    with fitz.open() as document:
        page = document.new_page()
        page.insert_text((72, 72), "DualMind AI reads PDF documents.")
        document.save(pdf_path)

    pages = extract_pdf_pages(str(pdf_path))

    assert len(pages) == 1
    assert pages[0]["page"] == 1
    assert "DualMind AI" in pages[0]["text"]


def test_chunk_pages_preserves_page_numbers():
    pages = [{"page": 3, "text": "abcdefghij"}]

    chunks = chunk_pages(pages, chunk_size=6, overlap=2)

    assert [chunk["text"] for chunk in chunks] == [
        "abcdef", "efghij", "ij"
    ]
    assert all(chunk["page"] == 3 for chunk in chunks)


def test_chunk_pages_rejects_invalid_overlap():
    with pytest.raises(ValueError):
        chunk_pages([], chunk_size=10, overlap=10)


def test_extract_pdf_rejects_non_pdf(tmp_path):
    file_path = tmp_path / "notes.txt"
    file_path.write_text("Not a PDF")

    with pytest.raises(ValueError):
        extract_pdf_pages(str(file_path))
