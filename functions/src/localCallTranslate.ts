import { initializeApp } from "firebase/app";
import { connectAuthEmulator, getAuth, signInAnonymously } from "firebase/auth";
import { connectFunctionsEmulator, getFunctions, httpsCallable } from "firebase/functions";

type TranslateResponse = { translatedText: string };

async function main() {
  const targetLanguage = process.argv[2] || "Spanish";
  const text =
    process.argv.slice(3).join(" ") ||
    "Hello! How can I help you today? (testing culturally-aware translation)";

  const projectId = process.env.FIREBASE_PROJECT_ID?.trim() || "lexai-ecc36";

  // Minimal Firebase client config for emulator usage.
  // For emulators, these values can be placeholders; the SDK uses the emulator endpoints.
  const app = initializeApp({
    apiKey: "fake-api-key",
    authDomain: "lexai.local",
    projectId,
  });

  const auth = getAuth(app);
  connectAuthEmulator(auth, "http://127.0.0.1:9099", { disableWarnings: true });
  await signInAnonymously(auth);

  const functions = getFunctions(app, "us-central1");
  connectFunctionsEmulator(functions, "127.0.0.1", 5001);

  const translateText = httpsCallable<{ text: string; targetLanguage: string }, TranslateResponse>(
    functions,
    "translateText"
  );

  const result = await translateText({ text, targetLanguage });
  console.log(result.data.translatedText);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});

