"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.translateText = void 0;
const https_1 = require("firebase-functions/v2/https");
const v2_1 = require("firebase-functions/v2");
const openai_1 = __importDefault(require("openai"));
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
function buildTranslationInstructions(args) {
    const { targetLanguage, sourceLanguage, style, context } = args;
    const styleLine = style
        ? `Style preference: ${style}.`
        : "Style preference: keep the same tone and politeness level as the original.";
    const sourceLine = sourceLanguage
        ? `Source language is: ${sourceLanguage}.`
        : "Detect the source language automatically.";
    const contextLine = context ? `Extra context: ${context}` : undefined;
    return [
        "You are a translation engine specialized in culturally-aware, nuanced translation.",
        `Translate the USER_TEXT into ${targetLanguage}.`,
        sourceLine,
        styleLine,
        "Requirements:",
        "- Preserve meaning exactly. Do not add, remove, or invent facts.",
        "- Maintain register (formal/informal), politeness, and intent.",
        "- Prefer natural, culturally appropriate phrasing over literal word-for-word translation.",
        "- Keep names, bill numbers, citations, and URLs unchanged.",
        "- If the text contains legal/legislative language, keep it precise (no paraphrasing).",
        "- Output ONLY the translated text. No quotes, no preface, no explanations.",
        ...(contextLine ? [contextLine] : []),
    ].join("\n");
}
async function translateWithChatGPT(args) {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
        throw new https_1.HttpsError("failed-precondition", "OPENAI_API_KEY is not configured for Functions.");
    }
    const model = process.env.OPENAI_TRANSLATION_MODEL?.trim() || "gpt-4.1-mini";
    const client = new openai_1.default({ apiKey });
    const instructions = buildTranslationInstructions({
        targetLanguage: args.targetLanguage,
        ...(args.sourceLanguage ? { sourceLanguage: args.sourceLanguage } : {}),
        ...(args.style ? { style: args.style } : {}),
        ...(args.context ? { context: args.context } : {}),
    });
    const resp = await client.chat.completions.create({
        model,
        messages: [
            { role: "system", content: instructions },
            { role: "user", content: args.text },
        ],
        temperature: 0.2,
    });
    const translated = resp.choices[0]?.message?.content?.trim();
    if (!translated) {
        throw new https_1.HttpsError("internal", "Translation provider returned empty output");
    }
    return translated;
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
    const provider = (process.env.TRANSLATION_PROVIDER || "chatgpt").trim();
    if (provider !== "chatgpt") {
        throw new https_1.HttpsError("failed-precondition", `Unsupported TRANSLATION_PROVIDER '${provider}' (supported: chatgpt)`);
    }
    const translatedText = await translateWithChatGPT({
        text,
        targetLanguage,
        ...(sourceLanguage ? { sourceLanguage } : {}),
        ...(style ? { style } : {}),
        ...(context ? { context } : {}),
    });
    return { translatedText };
});
