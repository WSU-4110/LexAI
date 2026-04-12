#Github and git

CSC4110 Term Project - LexAI

Hassan Alkhafaji - hq3720

## Server-side deployment (Firebase Cloud Functions)

This repo includes a Firebase Callable Function used by the iOS app for culturally-aware translation:

- **Function**: `translateText` (region: `us-central1`)
- **Auth**: required (callable will return `unauthenticated` if the user is not signed in)
- **Env vars required in Cloud**:
  - `OPENAI_API_KEY`
  - `OPENAI_TRANSLATION_MODEL` (optional, defaults to `gpt-4.1-mini`)
  - `TRANSLATION_PROVIDER` (optional, defaults to `chatgpt`)

### Deploy steps

1. Ensure you’re logged into Firebase and have a project selected:

```bash
npx -y firebase-tools@latest login
npx -y firebase-tools@latest use --add <FIREBASE_PROJECT_ID>
```

2. Set the required environment variables **server-side** (do not commit secrets).
   - Configure `OPENAI_API_KEY` for the deployed function using your preferred secure method (e.g. Google Cloud Secret Manager / Firebase secrets, or Cloud Functions environment variables).

3. Deploy Functions:

```bash
cd functions
npm ci
npm run deploy
```

See `functions/README.md` for emulator-first local testing instructions.
