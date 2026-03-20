export type ProviderMode = "openai" | "gemini" | "duo";

export type TranscriptMessage = {
  role: "user" | "assistant";
  content: string;
};

export type ChatRequestPayload = {
  provider: ProviderMode;
  input: string;
  systemPrompt?: string;
  openaiModel?: string;
  geminiModel?: string;
  messages?: TranscriptMessage[];
};

export type ProviderAnswer = {
  provider: "openai" | "gemini";
  model: string;
  text: string;
};

export type ChatResponsePayload =
  | {
      mode: "openai" | "gemini";
      answer: ProviderAnswer;
    }
  | {
      mode: "duo";
      answers: {
        openai: ProviderAnswer;
        gemini: ProviderAnswer;
      };
    };
