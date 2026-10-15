
import json
from pathlib import Path

import faiss


class DocumentStore:
    """Save and load a separate search index for each document."""

    def __init__(self, storage_dir: str):
        self.storage_dir = Path(storage_dir)
        self.storage_dir.mkdir(parents=True, exist_ok=True)

    def save(self, document_id: str, index, chunks: list[dict]) -> None:
        if not document_id or Path(document_id).name != document_id:
            raise ValueError("Invalid document ID.")

        if index.ntotal != len(chunks):
            raise ValueError("Index and chunk counts do not match.")

        document_dir = self.storage_dir / document_id
        document_dir.mkdir(parents=True, exist_ok=True)

        faiss.write_index(index, str(document_dir / "index.faiss"))

        (document_dir / "chunks.json").write_text(
            json.dumps(chunks, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

    def load(self, document_id: str) -> tuple:
        if not document_id or Path(document_id).name != document_id:
            raise ValueError("Invalid document ID.")

        document_dir = self.storage_dir / document_id
        index_path = document_dir / "index.faiss"
        chunks_path = document_dir / "chunks.json"

        if not index_path.is_file() or not chunks_path.is_file():
            raise FileNotFoundError("Document index not found.")

        index = faiss.read_index(str(index_path))
        chunks = json.loads(chunks_path.read_text(encoding="utf-8"))

        if index.ntotal != len(chunks):
            raise ValueError("Stored index and metadata do not match.")

        return index, chunks
