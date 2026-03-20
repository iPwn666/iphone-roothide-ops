import { NextResponse } from "next/server";
import { z } from "zod";

import { askGemini, askOpenAI } from "@/lib/provider-clients";
import type { TranscriptMessage } from "@/lib/types";

export const runtime = "nodejs";

const requestSchema = z.object({
  provider: z.enum(["openai", "gemini", "duo"]),
  input: z.string().trim().min(1).max(12000),
  systemPrompt: z.string().max(12000).optional().default(""),
  openaiModel: z.string().optional(),
  geminiModel: z.string().optional(),
  messages: z
    .array(
      z.object({
        role: z.enum(["user", "assistant"]),
        content: z.string().trim().min(1).max(12000),
      }),
    )
    .max(40)
    .optional()
    .default([]),
});

function sanitizeHistory(messages: TranscriptMessage[], input: string) {
  return [...messages.slice(-16), { role: "user" as const, content: input }];
}

export async function POST(request: Request) {
  try {
    const payload = requestSchema.parse(await request.json());
    const messages = sanitizeHistory(payload.messages, payload.input);

    if (payload.provider === "openai") {
      const answer = await askOpenAI({
        model: payload.openaiModel,
        systemPrompt: payload.systemPrompt,
        messages,
      });

      return NextResponse.json({ mode: "openai", answer });
    }

    if (payload.provider === "gemini") {
      const answer = await askGemini({
        model: payload.geminiModel,
        systemPrompt: payload.systemPrompt,
        messages,
      });

      return NextResponse.json({ mode: "gemini", answer });
    }

    const [openai, gemini] = await Promise.all([
      askOpenAI({
        model: payload.openaiModel,
        systemPrompt: payload.systemPrompt,
        messages,
      }),
      askGemini({
        model: payload.geminiModel,
        systemPrompt: payload.systemPrompt,
        messages,
      }),
    ]);

    return NextResponse.json({
      mode: "duo",
      answers: {
        openai,
        gemini,
      },
    });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unexpected chat route failure.";
    return NextResponse.json(
      {
        error: message,
      },
      { status: 400 },
    );
  }
}
