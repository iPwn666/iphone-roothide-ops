"use client";

import { useEffect, useMemo, useState } from "react";

import type { ChatResponsePayload, ProviderMode, TranscriptMessage } from "@/lib/types";

type ProviderFlags = {
  openai: boolean;
  gemini: boolean;
};

type BootstrapPayload = {
  providers: ProviderFlags;
  defaults: {
    openaiModel: string;
    geminiModel: string;
  };
  models: {
    openai: string[];
    gemini: string[];
  };
};

type ConversationEntry = {
  id: string;
  role: "user" | "assistant";
  createdAt: number;
  text?: string;
  provider?: "openai" | "gemini";
  model?: string;
  pending?: boolean;
  duo?: {
    openai: {
      text: string;
      model: string;
    };
    gemini: {
      text: string;
      model: string;
    };
  };
};

type PersistedState = {
  provider: ProviderMode;
  openaiModel: string;
  geminiModel: string;
  systemPrompt: string;
  messages: ConversationEntry[];
};

const STORAGE_KEY = "topops-ai-state-v1";

const QUICK_PROMPTS = [
  "Design a safe remote workflow for a jailbroken iPhone.",
  "Compare the same answer from OpenAI and Gemini.",
  "Turn a rough idea into a polished product brief.",
  "Write a recovery checklist for a broken mobile dev environment.",
];

function uid() {
  return typeof crypto !== "undefined" && "randomUUID" in crypto
    ? crypto.randomUUID()
    : `${Date.now()}-${Math.random().toString(36).slice(2)}`;
}

function entryToTranscript(entry: ConversationEntry): TranscriptMessage | null {
  if (entry.pending) {
    return null;
  }

  if (entry.role === "user" && entry.text) {
    return { role: "user", content: entry.text };
  }

  if (entry.role === "assistant" && entry.duo) {
    return {
      role: "assistant",
      content: `OpenAI:\n${entry.duo.openai.text}\n\nGemini:\n${entry.duo.gemini.text}`,
    };
  }

  if (entry.role === "assistant" && entry.text) {
    return { role: "assistant", content: entry.text };
  }

  return null;
}

export function TopOpsShell() {
  const [ready, setReady] = useState(false);
  const [provider, setProvider] = useState<ProviderMode>("duo");
  const [openaiModel, setOpenaiModel] = useState("gpt-4.1-mini");
  const [geminiModel, setGeminiModel] = useState("gemini-2.5-flash");
  const [systemPrompt, setSystemPrompt] = useState(
    "You are TopOps AI: crisp, practical, iPhone-first, and precise. Prefer clear action over abstract explanation.",
  );
  const [messages, setMessages] = useState<ConversationEntry[]>([]);
  const [input, setInput] = useState("");
  const [isSending, setIsSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [bootstrap, setBootstrap] = useState<BootstrapPayload | null>(null);
  const [notificationState, setNotificationState] = useState("unknown");
  const [micState, setMicState] = useState("unknown");
  const [standalone, setStandalone] = useState(false);

  useEffect(() => {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (raw) {
      try {
        const parsed = JSON.parse(raw) as PersistedState;
        setProvider(parsed.provider);
        setOpenaiModel(parsed.openaiModel);
        setGeminiModel(parsed.geminiModel);
        setSystemPrompt(parsed.systemPrompt);
        setMessages(parsed.messages);
      } catch {
        window.localStorage.removeItem(STORAGE_KEY);
      }
    }

    const media = window.matchMedia?.("(display-mode: standalone)");
    setStandalone(Boolean(media?.matches));
    setNotificationState(
      typeof Notification !== "undefined" ? Notification.permission : "unsupported",
    );
    void refreshMicrophoneState();
    void loadBootstrap();
  }, []);

  useEffect(() => {
    if (!ready) {
      return;
    }

    const payload: PersistedState = {
      provider,
      openaiModel,
      geminiModel,
      systemPrompt,
      messages,
    };
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(payload));
  }, [ready, provider, openaiModel, geminiModel, systemPrompt, messages]);

  async function loadBootstrap() {
    try {
      const response = await fetch("/api/bootstrap", { cache: "no-store" });
      const payload = (await response.json()) as BootstrapPayload;
      setBootstrap(payload);
      setOpenaiModel((current) => current || payload.defaults.openaiModel);
      setGeminiModel((current) => current || payload.defaults.geminiModel);
    } finally {
      setReady(true);
    }
  }

  async function refreshMicrophoneState() {
    try {
      if (!navigator.permissions) {
        setMicState("unsupported");
        return;
      }

      const status = await navigator.permissions.query({
        name: "microphone" as PermissionName,
      });
      setMicState(status.state);
    } catch {
      setMicState("prompt");
    }
  }

  async function requestNotifications() {
    if (typeof Notification === "undefined") {
      setNotificationState("unsupported");
      return;
    }

    const result = await Notification.requestPermission();
    setNotificationState(result);
  }

  async function requestMicrophone() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      stream.getTracks().forEach((track) => track.stop());
      await refreshMicrophoneState();
    } catch {
      setMicState("denied");
    }
  }

  function resetConversation() {
    setMessages([]);
    setError(null);
  }

  function queueQuickPrompt(prompt: string) {
    setInput(prompt);
  }

  async function sendMessage() {
    const trimmed = input.trim();
    if (!trimmed || isSending) {
      return;
    }

    setError(null);
    setIsSending(true);

    const userEntry: ConversationEntry = {
      id: uid(),
      role: "user",
      text: trimmed,
      createdAt: Date.now(),
    };

    const pendingEntry: ConversationEntry = {
      id: uid(),
      role: "assistant",
      pending: true,
      createdAt: Date.now(),
      text: provider === "duo" ? "Querying both models..." : "Thinking...",
    };

    const nextMessages = [...messages, userEntry, pendingEntry];
    setMessages(nextMessages);
    setInput("");

    try {
      const response = await fetch("/api/chat", {
        method: "POST",
        headers: {
          "content-type": "application/json",
        },
        body: JSON.stringify({
          provider,
          input: trimmed,
          systemPrompt,
          openaiModel,
          geminiModel,
          messages: messages.map(entryToTranscript).filter(Boolean),
        }),
      });

      const payload = (await response.json()) as ChatResponsePayload & {
        error?: string;
      };

      if (!response.ok || payload.error) {
        throw new Error(payload.error || "Chat request failed.");
      }

      const assistantEntry: ConversationEntry =
        payload.mode === "duo"
          ? {
              id: pendingEntry.id,
              role: "assistant",
              createdAt: pendingEntry.createdAt,
              duo: {
                openai: payload.answers.openai,
                gemini: payload.answers.gemini,
              },
            }
          : {
              id: pendingEntry.id,
              role: "assistant",
              createdAt: pendingEntry.createdAt,
              text: payload.answer.text,
              provider: payload.answer.provider,
              model: payload.answer.model,
            };

      setMessages((current) =>
        current.map((entry) => (entry.id === pendingEntry.id ? assistantEntry : entry)),
      );
    } catch (caughtError) {
      const message =
        caughtError instanceof Error ? caughtError.message : "Unknown request failure.";
      setError(message);
      setMessages((current) =>
        current.map((entry) =>
          entry.id === pendingEntry.id
            ? {
                ...entry,
                pending: false,
                text: message,
              }
            : entry,
        ),
      );
    } finally {
      setIsSending(false);
    }
  }

  const providerFlags = bootstrap?.providers || { openai: false, gemini: false };
  const transcriptCount = useMemo(
    () => messages.filter((entry) => entry.role === "assistant" && !entry.pending).length,
    [messages],
  );

  return (
    <main className="shell">
      <div className="shell__glow shell__glow--top" />
      <div className="shell__glow shell__glow--bottom" />

      <section className="hero glass">
        <div>
          <p className="eyebrow">TopOps AI</p>
          <h1>Native-feeling AI cockpit for OpenAI and Gemini.</h1>
          <p className="hero__copy">
            Built for iPhone-first workflows: one-touch compare mode, local
            persistence, server-side key handling, and an interface that feels
            closer to a polished app than a demo page.
          </p>
        </div>

        <div className="hero__meta">
          <StatusPill title="OpenAI" value={providerFlags.openai ? "ready" : "missing key"} />
          <StatusPill title="Gemini" value={providerFlags.gemini ? "ready" : "missing key"} />
          <StatusPill title="PWA" value={standalone ? "installed" : "browser mode"} />
        </div>
      </section>

      <div className="layout">
        <aside className="rail">
          <section className="glass panel">
            <div className="panel__header">
              <h2>Provider</h2>
              <span>{provider.toUpperCase()}</span>
            </div>

            <div className="segmented">
              {(["duo", "openai", "gemini"] as ProviderMode[]).map((mode) => {
                const disabled =
                  (mode === "openai" && !providerFlags.openai) ||
                  (mode === "gemini" && !providerFlags.gemini) ||
                  (mode === "duo" && (!providerFlags.openai || !providerFlags.gemini));

                return (
                  <button
                    key={mode}
                    className={`segmented__button ${provider === mode ? "is-active" : ""}`}
                    disabled={disabled}
                    onClick={() => setProvider(mode)}
                    type="button"
                  >
                    {mode === "duo" ? "Blend" : mode}
                  </button>
                );
              })}
            </div>

            <label className="field">
              <span>OpenAI model</span>
              <select value={openaiModel} onChange={(event) => setOpenaiModel(event.target.value)}>
                {(bootstrap?.models.openai || [openaiModel]).map((model) => (
                  <option key={model} value={model}>
                    {model}
                  </option>
                ))}
              </select>
            </label>

            <label className="field">
              <span>Gemini model</span>
              <select value={geminiModel} onChange={(event) => setGeminiModel(event.target.value)}>
                {(bootstrap?.models.gemini || [geminiModel]).map((model) => (
                  <option key={model} value={model}>
                    {model}
                  </option>
                ))}
              </select>
            </label>
          </section>

          <section className="glass panel">
            <div className="panel__header">
              <h2>Mission</h2>
              <span>persistent</span>
            </div>
            <label className="field">
              <span>System prompt</span>
              <textarea
                rows={7}
                value={systemPrompt}
                onChange={(event) => setSystemPrompt(event.target.value)}
              />
            </label>

            <div className="quick-grid">
              {QUICK_PROMPTS.map((prompt) => (
                <button
                  key={prompt}
                  className="quick-grid__button"
                  onClick={() => queueQuickPrompt(prompt)}
                  type="button"
                >
                  {prompt}
                </button>
              ))}
            </div>
          </section>

          <section className="glass panel">
            <div className="panel__header">
              <h2>Permissions</h2>
              <span>optional</span>
            </div>
            <div className="permission-row">
              <div>
                <strong>Notifications</strong>
                <p>{notificationState}</p>
              </div>
              <button onClick={requestNotifications} type="button">
                Request
              </button>
            </div>
            <div className="permission-row">
              <div>
                <strong>Microphone</strong>
                <p>{micState}</p>
              </div>
              <button onClick={requestMicrophone} type="button">
                Request
              </button>
            </div>
            <p className="footnote">
              Conversation state persists locally in this browser. Keys stay
              server-side.
            </p>
          </section>
        </aside>

        <section className="conversation">
          <section className="glass panel panel--conversation">
            <div className="panel__header">
              <h2>Conversation</h2>
              <span>{transcriptCount} response(s)</span>
            </div>

            <div className="transcript">
              {messages.length === 0 ? (
                <div className="empty-state">
                  <h3>Start with a high-signal question.</h3>
                  <p>
                    Blend mode asks OpenAI and Gemini in parallel, then shows
                    both answers side by side.
                  </p>
                </div>
              ) : (
                messages.map((entry) => (
                  <article
                    key={entry.id}
                    className={`bubble bubble--${entry.role} ${entry.pending ? "is-pending" : ""}`}
                  >
                    <header className="bubble__meta">
                      <span>{entry.role === "user" ? "You" : "Assistant"}</span>
                      {entry.model ? <span>{entry.model}</span> : null}
                    </header>

                    {entry.duo ? (
                      <div className="compare-grid">
                        <div className="compare-card">
                          <div className="compare-card__header">
                            <strong>OpenAI</strong>
                            <span>{entry.duo.openai.model}</span>
                          </div>
                          <p>{entry.duo.openai.text}</p>
                        </div>
                        <div className="compare-card">
                          <div className="compare-card__header">
                            <strong>Gemini</strong>
                            <span>{entry.duo.gemini.model}</span>
                          </div>
                          <p>{entry.duo.gemini.text}</p>
                        </div>
                      </div>
                    ) : (
                      <p>{entry.text}</p>
                    )}
                  </article>
                ))
              )}
            </div>
          </section>
        </section>
      </div>

      {error ? <div className="toast-error">{error}</div> : null}

      <form
        className="composer glass"
        onSubmit={(event) => {
          event.preventDefault();
          void sendMessage();
        }}
      >
        <textarea
          rows={2}
          value={input}
          onChange={(event) => setInput(event.target.value)}
          placeholder="Ask for a deployment plan, debugging flow, architecture critique, or direct compare answer..."
        />
        <div className="composer__actions">
          <button className="button-secondary" onClick={resetConversation} type="button">
            Reset
          </button>
          <button className="button-primary" disabled={isSending || !input.trim()} type="submit">
            {isSending ? "Working..." : provider === "duo" ? "Run Both" : "Send"}
          </button>
        </div>
      </form>
    </main>
  );
}

function StatusPill({ title, value }: { title: string; value: string }) {
  return (
    <div className="status-pill">
      <span>{title}</span>
      <strong>{value}</strong>
    </div>
  );
}
