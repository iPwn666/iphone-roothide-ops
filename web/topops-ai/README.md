# TopOps AI Web

Mobile-first, iOS-like AI cockpit that combines:

- OpenAI Responses API via the official `openai` JavaScript SDK
- Google Gemini via the official REST `generateContent` endpoint
- local-first conversation persistence in the browser
- comparison mode that asks both providers in parallel

## Local setup

1. Copy `.env.local.example` to `.env.local`.
2. Fill in your own `OPENAI_API_KEY` and `GOOGLE_GEMINI_API_KEY`.
3. Install and run:

```bash
npm install
npm run dev
```

## Security

- Keys stay server-side in Next.js route handlers.
- Do not commit `.env.local`.
- If any API key was pasted into chat or shared elsewhere, rotate it.

## Providers

- OpenAI uses `POST /v1/responses` via the official SDK.
- Gemini uses `POST /v1beta/models/{model}:generateContent`.
