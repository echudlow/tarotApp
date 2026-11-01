import { PRIVACY_HTML } from "./privacy.js";

// The Read proxy: holds the Anthropic key, limits usage per device, streams the reply back.

const MODEL = "claude-haiku-4-5-20251001";
const MAX_TOKENS_CAP = 2500;
const DEVICE_DAILY_LIMIT = 30;     // readings per device per day
const GLOBAL_DAILY_LIMIT = 3000;   // readings per day across everyone
const MAX_BODY_BYTES = 40_000;
const ALLOWED_FIELDS = ["model", "max_tokens", "system", "messages", "stream", "temperature"];

const json = (obj, status = 200) =>
  new Response(JSON.stringify(obj), { status, headers: { "content-type": "application/json" } });

// Count a use against a KV key for today. Returns the new count.
async function bump(kv, key) {
  const current = parseInt((await kv.get(key)) || "0", 10) + 1;
  await kv.put(key, String(current), { expirationTtl: 60 * 60 * 36 });
  return current;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "GET" && url.pathname === "/privacy") {
      return new Response(PRIVACY_HTML, { headers: { "content-type": "text/html; charset=utf-8" } });
    }

    if (request.method !== "POST" || url.pathname !== "/v1/messages") {
      return json({ error: "not found" }, 404);
    }

    const deviceID = request.headers.get("x-device-id") || "";
    if (!/^[0-9A-Fa-f-]{36}$/.test(deviceID)) {
      return json({ error: "bad device id" }, 400);
    }

    const raw = await request.text();
    if (raw.length > MAX_BODY_BYTES) return json({ error: "too large" }, 413);

    let body;
    try { body = JSON.parse(raw); } catch { return json({ error: "bad json" }, 400); }
    if (!Array.isArray(body.messages) || body.messages.length === 0) {
      return json({ error: "bad request" }, 400);
    }

    // Only pass through known fields, and pin the model and size
    const clean = {};
    for (const k of ALLOWED_FIELDS) if (k in body) clean[k] = body[k];
    clean.model = MODEL;
    clean.max_tokens = Math.min(Number(clean.max_tokens) || 1500, MAX_TOKENS_CAP);

    // Limits
    const day = new Date().toISOString().slice(0, 10);
    const globalCount = await bump(env.LIMITS, `g:${day}`);
    if (globalCount > GLOBAL_DAILY_LIMIT) return json({ error: "busy", code: "global_limit" }, 429);
    const deviceCount = await bump(env.LIMITS, `d:${deviceID}:${day}`);
    if (deviceCount > DEVICE_DAILY_LIMIT) return json({ error: "limit", code: "device_limit" }, 429);

    const upstream = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": env.ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify(clean),
    });

    // Stream the body straight through (works for both normal and SSE replies)
    return new Response(upstream.body, {
      status: upstream.status,
      headers: {
        "content-type": upstream.headers.get("content-type") || "application/json",
        "cache-control": "no-store",
      },
    });
  },
};
