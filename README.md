# DualMind AI 🧠

**An AI-powered document research assistant built with Flutter, Flask, and Groq.**

DualMind AI helps users understand PDF documents, explore general topics, and connect document evidence with broader knowledge through three question-answering modes.

## ✨ Features

- **PDF Upload:** Upload and process PDF documents.
- **Document Mode:** Ask questions based on an uploaded PDF, with page references.
- **General Knowledge Mode:** Ask questions without uploading a document.
- **Combined Mode:** Use document passages alongside general knowledge.
- **Semantic Search:** Retrieve relevant document passages for question-answering.
- **Source References:** Review supporting passages from your document.

## 🛠️ Tech Stack

| Component | Technology |
|---|---|
| Frontend | Flutter, Dart |
| Backend | Python, Flask |
| AI model API | Groq |
| PDF processing | PyMuPDF |
| Embeddings | Sentence Transformers |
| Vector search | FAISS |
| HTTP requests | Flutter HTTP package |

## 📁 Project Structure

```text
dualmind-ai/
├── backend/
│   └── app/
├── frontend/
│   ├── lib/
│   ├── test/
│   └── pubspec.yaml
├── .gitignore
└── README.md
```

## 🚀 Getting Started

### Prerequisites

- Python installed
- Flutter SDK installed
- A Groq API key

### 1. Clone the repository

Replace `Rabiyapathan` with your GitHub username.

```bash
git clone https://github.com/Rabiyapathan/dualmind-ai.git
cd dualmind-ai
```

### 2. Set up the backend

From the project root:

```bash
python -m venv .venv
source .venv/bin/activate
```

Install the backend dependencies using the dependency file provided in the repository. If no dependency file exists yet, create one before following this step.

Create a `.env` file in the project root:

```env
GROQ_API_KEY=your_groq_api_key
GROQ_MODEL=openai/gpt-oss-120b
```

Replace the placeholder with your own API key. Never commit this file.

Start the backend:

```bash
python -m flask --app backend.app:create_app run --debug
```

The backend runs locally at `http://127.0.0.1:5000`.

### 3. Set up the Flutter frontend

Open a second terminal:

```bash
cd frontend
flutter pub get
flutter run -d linux
```

The current frontend uses a local backend URL. Update the API URL before running the frontend against a deployed backend.

## 🧪 Testing

### Backend

From the project root, with the virtual environment activated:

```bash
pytest -q
```

### Frontend

```bash
cd frontend
flutter analyze
flutter test
```

## 🔐 Security

- Keep API keys in environment variables.
- Do not commit `.env` files, virtual environments, or private uploaded documents.
- Review `.gitignore` before pushing the repository.
- Add authentication and suitable access controls before exposing the application publicly.

## 📌 Project Status

The core application and three question-answering modes have been implemented. Backend tests and Flutter checks have been run locally.

Future improvements may include further UI refinement, deployment, and additional integration testing.

## 👩‍💻 Author

**Rabiya Pathan**

DualMind AI is a learning project exploring AI-powered applications, document retrieval, and Flutter–Flask integration.
