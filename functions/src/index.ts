import { onCall, HttpsError } from "firebase-functions/v2/https";
import { setGlobalOptions } from "firebase-functions/v2";
import { translateWithChatGPT } from "./translation";

setGlobalOptions({
  region: "us-central1",
});

type TranslateTextRequest = {
  text: unknown;
  targetLanguage: unknown;
  sourceLanguage?: unknown;
  style?: unknown;
  context?: unknown;
};

type TranslateTextResponse = {
  translatedText: string;
};

type GenerateAnswerRequest = {
  prompt: unknown;
  targetLanguage: unknown;
};

type GenerateAnswerResponse = {
  originalText: string;
  displayText: string;
  targetLanguage: string;
};

const ALLOWED_TARGET_LANGUAGES = new Set([
  "English",
  "Spanish",
  "French",
  "Arabic",
  "German",
]);

function expectString(value: unknown, field: string): string {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", `${field} must be a string`);
  }
  return value;
}

function normalizeOptionalString(value: unknown): string | undefined {
  if (value === undefined || value === null) return undefined;
  if (typeof value !== "string") return undefined;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

export const translateText = onCall<TranslateTextRequest, Promise<TranslateTextResponse>>(
  {
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication is required.");
    }

    const text = expectString(request.data.text, "text").trim();
    const targetLanguage = expectString(
      request.data.targetLanguage,
      "targetLanguage"
    ).trim();

    if (text.length === 0) {
      throw new HttpsError("invalid-argument", "text must not be empty");
    }
    if (text.length > 8000) {
      throw new HttpsError(
        "invalid-argument",
        "text is too long (max 8000 characters)"
      );
    }

    if (!ALLOWED_TARGET_LANGUAGES.has(targetLanguage)) {
      throw new HttpsError(
        "invalid-argument",
        `targetLanguage must be one of: ${Array.from(ALLOWED_TARGET_LANGUAGES).join(
          ", "
        )}`
      );
    }

    const sourceLanguage = normalizeOptionalString(request.data.sourceLanguage);
    const style = normalizeOptionalString(request.data.style);
    const context = normalizeOptionalString(request.data.context);

    const translatedText = await translateWithChatGPT({
      text,
      targetLanguage,
      ...(sourceLanguage ? { sourceLanguage } : {}),
      ...(style ? { style } : {}),
      ...(context ? { context } : {}),
    });

    return { translatedText };
  }
);

export const generateAnswer = onCall<
  GenerateAnswerRequest,
  Promise<GenerateAnswerResponse>
>(
  {
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication is required.");
    }

    const prompt = expectString(request.data.prompt, "prompt").trim();
    const targetLanguage = expectString(
      request.data.targetLanguage,
      "targetLanguage"
    ).trim();

    if (prompt.length === 0) {
      throw new HttpsError("invalid-argument", "prompt must not be empty");
    }
    if (prompt.length > 8000) {
      throw new HttpsError(
        "invalid-argument",
        "prompt is too long (max 8000 characters)"
      );
    }

    if (!ALLOWED_TARGET_LANGUAGES.has(targetLanguage)) {
      throw new HttpsError(
        "invalid-argument",
        `targetLanguage must be one of: ${Array.from(ALLOWED_TARGET_LANGUAGES).join(
          ", "
        )}`
      );
    }

    // Placeholder answer until the tuned model is available.
    const originalText = "Hello! How can I help you today?";

    if (targetLanguage === "English") {
      return { originalText, displayText: originalText, targetLanguage };
    }

    const displayText = await translateWithChatGPT({
      text: originalText,
      targetLanguage,
      context:
        "This text is an assistant reply. Keep it natural for a chat assistant.",
    });

    return { originalText, displayText, targetLanguage };
  }
);
