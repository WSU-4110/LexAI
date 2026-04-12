"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const app_1 = require("firebase/app");
const auth_1 = require("firebase/auth");
const functions_1 = require("firebase/functions");
async function main() {
    const targetLanguage = process.argv[2] || "Spanish";
    const text = process.argv.slice(3).join(" ") ||
        "Hello! How can I help you today? (testing culturally-aware translation)";
    const projectId = process.env.FIREBASE_PROJECT_ID?.trim() || "lexai-ecc36";
    // Minimal Firebase client config for emulator usage.
    // For emulators, these values can be placeholders; the SDK uses the emulator endpoints.
    const app = (0, app_1.initializeApp)({
        apiKey: "fake-api-key",
        authDomain: "lexai.local",
        projectId,
    });
    const auth = (0, auth_1.getAuth)(app);
    (0, auth_1.connectAuthEmulator)(auth, "http://127.0.0.1:9099", { disableWarnings: true });
    await (0, auth_1.signInAnonymously)(auth);
    const functions = (0, functions_1.getFunctions)(app, "us-central1");
    (0, functions_1.connectFunctionsEmulator)(functions, "127.0.0.1", 5001);
    const translateText = (0, functions_1.httpsCallable)(functions, "translateText");
    const result = await translateText({ text, targetLanguage });
    console.log(result.data.translatedText);
}
main().catch((err) => {
    console.error(err);
    process.exitCode = 1;
});
