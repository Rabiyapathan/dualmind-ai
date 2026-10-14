from pathlib import Path

import fitz


def extract_pdf_pages(file_path: str) -> list[dict]:
    """Extract non-empty text from a PDF, preserving page numbers."""
    path = Path(file_path)

    if not path.is_file():
        raise FileNotFoundError(f"PDF not found: {path}")

    if path.suffix.lower() != ".pdf":
        raise ValueError("Only PDF files are supported.")

    pages = []

    with fitz.open(path) as document:
        if document.is_encrypted:
            raise ValueError("Encrypted PDFs are not supported yet.")

        for page_number, page in enumerate(document, start=1):
            text = page.get_text("text").strip()

            if text:
                pages.append({
                    "page": page_number,
                    "text": text,
                })

    return pages


def chunk_pages(
    pages: list[dict],
    chunk_size: int = 1000,
    overlap: int = 150,
) -> list[dict]:
    """Split page text into overlapping character-based chunks."""
    if chunk_size <= 0:
        raise ValueError("chunk_size must be positive.")

    if overlap < 0 or overlap >= chunk_size:
        raise ValueError("overlap must be >= 0 and < chunk_size.")

    chunks = []
    step = chunk_size - overlap

    for page in pages:
        text = page["text"].strip()

        for start in range(0, len(text), step):
            content = text[start:start + chunk_size].strip()

            if content:
                chunks.append({
                    "page": page["page"],
                    "text": content,
                })

    return chunks
