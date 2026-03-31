## LexAI Firebase Functions (PR1)

This directory adds an **emulator-first** Firebase Cloud Functions backend to support translation with nuance/cultural fidelity.

### What’s implemented

- **Callable**: `translateText`
  - **Request**: `{ text: string, targetLanguage: string, sourceLanguage?: string, style?: string, context?: string }`
  - **Response**: `{ translatedText: string }`
- **Provider**: ChatGPT (OpenAI) via `OPENAI_API_KEY`

### Local setup (emulator)

Prereqs:
- Install Firebase CLI on your machine (`firebase` command available)
- Node.js 22+

From repo root:

1. Install deps
   - `cd functions && npm i`

2. Set env vars for the emulator
   - In `functions/.env.local` (do **not** commit), add:

```bash
OPENAI_API_KEY="..."
OPENAI_TRANSLATION_MODEL="gpt-4.1-mini"
TRANSLATION_PROVIDER="chatgpt"
```

3. Start emulators
   - From repo root: `firebase emulators:start --only functions`

The iOS app already points to the Functions emulator at `127.0.0.1:5001` in DEBUG (see `LexAI_iOSApp.swift`).

### Deployment later

When your Firebase project is ready for Cloud Functions deploy (billing, APIs, etc.), the same code can be deployed with:

- `cd functions && npm run deploy`

#### Server-side configuration (required)

The deployed function expects these environment variables to be available **in the Cloud Functions runtime**:

- `OPENAI_API_KEY` (required)
- `OPENAI_TRANSLATION_MODEL` (optional; defaults to `gpt-4.1-mini`)
- `TRANSLATION_PROVIDER` (optional; defaults to `chatgpt`)

Do **not** commit API keys or service account credentials into the repo. Keep `.env.local` for local emulators only (and ensure it stays ignored).

