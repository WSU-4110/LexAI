"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateAnswer = exports.translateText = void 0;
const https_1 = require("firebase-functions/v2/https");
const v2_1 = require("firebase-functions/v2");
const translation_1 = require("./translation");
(0, v2_1.setGlobalOptions)({
    region: "us-central1",
});
const ALLOWED_TARGET_LANGUAGES = new Set([
    "English",
    "Spanish",
    "French",
    "Arabic",
    "German",
]);
function expectString(value, field) {
    if (typeof value !== "string") {
        throw new https_1.HttpsError("invalid-argument", `${field} must be a string`);
    }
    return value;
}
function normalizeOptionalString(value) {
    if (value === undefined || value === null)
        return undefined;
    if (typeof value !== "string")
        return undefined;
    const trimmed = value.trim();
    return trimmed.length > 0 ? trimmed : undefined;
}
exports.translateText = (0, https_1.onCall)({
    enforceAppCheck: false,
}, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Authentication is required.");
    }
    const text = expectString(request.data.text, "text").trim();
    const targetLanguage = expectString(request.data.targetLanguage, "targetLanguage").trim();
    if (text.length === 0) {
        throw new https_1.HttpsError("invalid-argument", "text must not be empty");
    }
    if (text.length > 8000) {
        throw new https_1.HttpsError("invalid-argument", "text is too long (max 8000 characters)");
    }
    if (!ALLOWED_TARGET_LANGUAGES.has(targetLanguage)) {
        throw new https_1.HttpsError("invalid-argument", `targetLanguage must be one of: ${Array.from(ALLOWED_TARGET_LANGUAGES).join(", ")}`);
    }
    const sourceLanguage = normalizeOptionalString(request.data.sourceLanguage);
    const style = normalizeOptionalString(request.data.style);
    const context = normalizeOptionalString(request.data.context);
    const translatedText = await (0, translation_1.translateWithChatGPT)({
        text,
        targetLanguage,
        ...(sourceLanguage ? { sourceLanguage } : {}),
        ...(style ? { style } : {}),
        ...(context ? { context } : {}),
    });
    return { translatedText };
});
exports.generateAnswer = (0, https_1.onCall)({
    enforceAppCheck: false,
}, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Authentication is required.");
    }
    const prompt = expectString(request.data.prompt, "prompt").trim();
    const targetLanguage = expectString(request.data.targetLanguage, "targetLanguage").trim();
    if (prompt.length === 0) {
        throw new https_1.HttpsError("invalid-argument", "prompt must not be empty");
    }
    if (prompt.length > 8000) {
        throw new https_1.HttpsError("invalid-argument", "prompt is too long (max 8000 characters)");
    }
    if (!ALLOWED_TARGET_LANGUAGES.has(targetLanguage)) {
        throw new https_1.HttpsError("invalid-argument", `targetLanguage must be one of: ${Array.from(ALLOWED_TARGET_LANGUAGES).join(", ")}`);
    }
    // Placeholder answer until the tuned model is available.
    const originalText = "Hello! How can I help you today?";
    if (targetLanguage === "English") {
        return { originalText, displayText: originalText, targetLanguage };
    }
    const displayText = await (0, translation_1.translateWithChatGPT)({
        text: originalText,
        targetLanguage,
        context: "This text is an assistant reply. Keep it natural for a chat assistant.",
    });
    return { originalText, displayText, targetLanguage };
});
