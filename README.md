# AI Resume Analyzer

An AI-powered Resume Analyzer and Job Matching System built with **Flutter** and rule-based/NLP-style local text analysis. It compares an uploaded PDF resume against a target job role or job description and produces an explainable **Resume Compatibility Score**, skill/keyword gap analysis, and actionable improvement suggestions — all running locally, with no paid APIs.

## Features

- **User accounts** — register, log in, edit profile, log out (local SQLite-backed auth)
- **Resume upload** — upload a PDF resume, extract and parse its text and sections
- **Job matching** — pick a predefined role (Flutter Developer, Java Developer, Python Developer, Web Developer, Data Analyst, AI/ML Intern) or paste a custom job description
- **Resume Compatibility Score (0–100)** — explainable, weighted breakdown across:
  - Skill Match (25)
  - Keyword Match (20)
  - Content Similarity (20)
  - Projects & Experience Relevance (15)
  - Resume Completeness (10)
  - Resume Structure (10)
- **Skill & keyword analysis** — matched, partially matched, and missing skills/keywords, without fabricating experience the resume doesn't support
- **Resume Optimizer** — suggestions separated into "from the job description" vs. "recommended for this role (industry standard)"
- **Analysis history** — every past analysis is saved and can be reopened in full
- **Responsive UI** — sidebar navigation on wide screens, a drawer on narrow/mobile screens

## Tech Stack

- Flutter / Dart
- SQLite (via `sqflite`, with web support via `sqflite_common_ffi_web`)
- `file_picker` for resume upload
- `syncfusion_flutter_pdf` for PDF text extraction
- Local, rule-based skill/keyword/similarity matching — no external AI API calls

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and on your PATH
- A device/emulator, or a browser (Chrome/Edge) for web

Check your setup with:

```bash
flutter doctor
```

### Run it

From the project root (the folder containing `pubspec.yaml`):

```bash
flutter pub get
flutter run
```

`flutter pub get` downloads the project's dependencies, and `flutter run` builds and launches the app on whichever connected device/emulator/browser Flutter picks by default.

To target a specific device, list what's available and pass `-d`:

```bash
flutter devices
flutter run -d chrome    # or: edge, windows, android, etc.
```

### Notes

- No API keys or external services are required — everything runs locally against a local SQLite database.
- On first run, register a new account from the login screen; there's no seeded demo user.
- Resumes must be text-based PDFs — scanned/image-only PDFs won't have extractable text.