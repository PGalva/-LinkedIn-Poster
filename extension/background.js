// Service worker: the ONLY part of the extension that talks to the API.
// The content script (feed) and the popup (Post Creator) send it messages;
// it maps each message type to an endpoint. Same idea as the LLM adapters:
// one place that knows the outside world.
//
// The AI key NEVER lives in the extension — it stays on the Rails server.
const API_URL = "http://localhost:9292";

const ROUTES = {
  "suggest-comment": (msg) => ["/comments/suggest", { post: msg.post }],
  "generate-post": (msg) => ["/posts/generate", { brief: msg.brief }],
  "check-post": (msg) => ["/posts/check", { body: msg.body, hashtags: msg.hashtags }],
  "rank-posts": (msg) => ["/posts/rank", { posts: msg.posts, limit: msg.limit }],
};

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  const route = ROUTES[message.type];
  if (!route) return false;

  const [path, body] = route(message);
  callApi(path, body).then(sendResponse);
  return true; // keep the channel open for the async response
});

async function callApi(path, body) {
  try {
    const res = await fetch(`${API_URL}${path}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    const data = await res.json();
    return res.ok ? { ok: true, data } : { ok: false, error: data.error ?? `HTTP ${res.status}` };
  } catch {
    return { ok: false, error: "API is offline. Start it with `docker compose up`." };
  }
}
