
from functools import lru_cache

import faiss
import numpy as np
from sentence_transformers import SentenceTransformer


@lru_cache(maxsize=2)
def load_embedding_model(model_name: str) -> SentenceTransformer:
    """Load and reuse an embedding model."""
    return SentenceTransformer(model_name, device="cpu")


class RetrievalService:
    def __init__(
        self,
        model_name="sentence-transformers/all-MiniLM-L6-v2",
    ):
        self.model = load_embedding_model(model_name)
        self.index = None
        self.chunks = []

    def build_index(self, chunks: list[dict]) -> None:
        """Create a searchable FAISS index from document chunks."""
        if not chunks:
            raise ValueError("Cannot build an index without chunks.")

        texts = [chunk["text"] for chunk in chunks]
        embeddings = self.model.encode(
            texts,
            convert_to_numpy=True,
            normalize_embeddings=True,
            show_progress_bar=False,
        )

        embeddings = np.asarray(embeddings, dtype=np.float32)

        self.index = faiss.IndexFlatIP(embeddings.shape[1])
        self.index.add(embeddings)
        self.chunks = chunks.copy()

    def search(
        self,
        question: str,
        top_k: int = 3,
        index=None,
        chunks: list[dict] | None = None,
    ) -> list[dict]:
        """Search the current index or a previously saved document index."""
        search_index = index if index is not None else self.index
        search_chunks = chunks if chunks is not None else self.chunks

        if search_index is None:
            raise RuntimeError("Build or load an index before searching.")

        if not question.strip():
            raise ValueError("Question cannot be empty.")

        if top_k < 1:
            raise ValueError("top_k must be at least 1.")

        if not search_chunks:
            return []

        query_embedding = self.model.encode(
            [question],
            convert_to_numpy=True,
            normalize_embeddings=True,
            show_progress_bar=False,
        )
        query_embedding = np.asarray(query_embedding, dtype=np.float32)

        scores, indices = search_index.search(
            query_embedding,
            min(top_k, len(search_chunks)),
        )

        results = []
        for score, chunk_index in zip(scores[0], indices[0]):
            if chunk_index < 0:
                continue

            chunk = search_chunks[int(chunk_index)]
            results.append({
                "page": chunk["page"],
                "text": chunk["text"],
                "score": float(score),
            })

        return results
