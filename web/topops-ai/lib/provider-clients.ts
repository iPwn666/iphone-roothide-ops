import OpenAI from "openai";

import type { TranscriptMessage } from "./types";

export const DEFAULT_OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-4.1-mini";
export const DEFAULT_GEMINI_MODEL = process.env.GEMINI_MODEL || "gemini-2.5-flash";

export const OPENAI_MODELS = [
  "gpt-5.4",
  "gpt-4.1-mini",
  "gpt-4o-mini",
  "o3-mini",
];

export const GEMINI_MODELS = [
  "gemini-2.5-flash",
  "gemini-2.5-pro",
  "gemini-3-flash-preview",
];

function requireKey(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function asOpenAIInput(messages: TranscriptMessage[]) {
  return messages.map((message) => ({
    role: message.role,
    content: [{ type: "input_text" as const, text: message.content }],
  }));
}

function extractOpenAIText(response: unknown): string {
  const candidate = response as {
    output_text?: string;
    output?: Array<{
      type?: string;
      content?: Array<{ type?: string; text?: string }>;
    }>;
  };

  if (typeof candidate.output_text === "string" && candidate.output_text.trim()) {
    return candidate.output_text.trim();
  }

  const chunks =
    candidate.output
      ?.flatMap((item) =>
        item.type === "message"
          ? (item.content || [])
              .filter((part) => part.type === "output_text" && typeof part.text === "string")
              .map((part) => part.text!.trim())
          : [],
      )
      .filter(Boolean) || [];

  if (!chunks.length) {
    throw new Error("OpenAI response did not include output_text.");
  }

  return chunks.join("\n\n");
}

function extractGeminiText(payload: unknown): string {
  const data = payload as {
    candidates?: Array<{
      content?: {
        parts?: Array<{ text?: string }>;
      };
    }>;
  };

  const text =
    data.candidates?.[0]?.content?.parts
      ?.map((part) => part.text?.trim())
      .filter(Boolean)
      .join("\n\n") || "";

  if (!text) {
    throw new Error("Gemini response did not include text content.");
  }

  return text;
}

export async function askOpenAI(args: {
  model?: string;
  systemPrompt?: string;
  messages: TranscriptMessage[];
}) {
  const client = new OpenAI({ apiKey: requireKey("OPENAI_API_KEY") });
  const model = args.model || DEFAULT_OPENAI_MODEL;

  const response = await client.responses.create({
    model,
    store: false,
    instructions: args.systemPrompt || undefined,
    input: asOpenAIInput(args.messages),
    text: {
      format: {
        type: "text",
      },
    },
  });

  return {
    provider: "openai" as const,
    model,
    text: extractOpenAIText(response),
  };
}

export async function askGemini(args: {
  model?: string;
  systemPrompt?: string;
  messages: TranscriptMessage[];
}) {
  const model = args.model || DEFAULT_GEMINI_MODEL;
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
    {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-goog-api-key": requireKey("GOOGLE_GEMINI_API_KEY"),
      },
      body: JSON.stringify({
        ...(args.systemPrompt
          ? {
              systemInstruction: {
                parts: [{ text: args.systemPrompt }],
              },
            }
          : {}),
        contents: args.messages.map((message) => ({
          role: message.role === "assistant" ? "model" : "user",
          parts: [{ text: message.content }],
        })),
        generationConfig: {
          temperature: 0.85,
          maxOutputTokens: 2048,
        },
      }),
    },
  );

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Gemini request failed: ${response.status} ${text}`);
  }

  const payload = await response.json();

  return {
    provider: "gemini" as const,
    model,
    text: extractGeminiText(payload),
  };
}
