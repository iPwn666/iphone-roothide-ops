import { NextResponse } from "next/server";

import {
  DEFAULT_GEMINI_MODEL,
  DEFAULT_OPENAI_MODEL,
  GEMINI_MODELS,
  OPENAI_MODELS,
} from "@/lib/provider-clients";

export const runtime = "nodejs";

export async function GET() {
  return NextResponse.json({
    providers: {
      openai: Boolean(process.env.OPENAI_API_KEY),
      gemini: Boolean(process.env.GOOGLE_GEMINI_API_KEY),
    },
    defaults: {
      openaiModel: DEFAULT_OPENAI_MODEL,
      geminiModel: DEFAULT_GEMINI_MODEL,
    },
    models: {
      openai: OPENAI_MODELS,
      gemini: GEMINI_MODELS,
    },
  });
}
