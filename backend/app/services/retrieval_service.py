
from sentence_transformers import SentenceTransformer
import faiss
import numpy as np


class RetrievalService:
    def __init__(self, model_name="sentence-transformers/all-MiniLM-L6-v2"):
        self.model = SentenceTransformer(model_name, device="cpu")
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

    def search(self, question: str, top_k: int = 3) -> list[dict]:
        """Return the most relevant chunks for a question."""
        if self.index is None:
            raise RuntimeError("Build the index before searching.")

        if not question.strip():
            raise ValueError("Question cannot be empty.")

        if top_k < 1:
            raise ValueError("top_k must be at least 1.")

        query_embedding = self.model.encode(
            [question],
            convert_to_numpy=True,
            normalize_embeddings=True,
            show_progress_bar=False,
        )
        query_embedding = np.asarray(query_embedding, dtype=np.float32)

        scores, indices = self.index.search(
            query_embedding,
            min(top_k, len(self.chunks)),
        )

        results = []
        for score, index in zip(scores[0], indices[0]):
            if index < 0:
                continue

            chunk = self.chunks[int(index)]
            results.append({
                "page": chunk["page"],
                "text": chunk["text"],
                "score": float(score),
            })

        return results
