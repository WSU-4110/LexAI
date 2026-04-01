import { HttpsError } from "firebase-functions/v2/https";
import OpenAI from "openai";

export type TranslateArgs = {
  text: string;
  targetLanguage: string;
  sourceLanguage?: string;
  style?: string;
  context?: string;
};

function buildTranslationInstructions(args: {
  targetLanguage: string;
  sourceLanguage?: string;
  style?: string;
  context?: string;
}): string {
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

export async function translateWithChatGPT(args: TranslateArgs): Promise<string> {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw new HttpsError(
      "failed-precondition",
      "OPENAI_API_KEY is not configured for Functions."
    );
  }

  const provider = (process.env.TRANSLATION_PROVIDER || "chatgpt").trim();
  if (provider !== "chatgpt") {
    throw new HttpsError(
      "failed-precondition",
      `Unsupported TRANSLATION_PROVIDER '${provider}' (supported: chatgpt)`
    );
  }

  const model = process.env.OPENAI_TRANSLATION_MODEL?.trim() || "gpt-4.1-mini";
  const client = new OpenAI({ apiKey });

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
    throw new HttpsError("internal", "Translation provider returned empty output");
  }
  return translated;
}

