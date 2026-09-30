// Service worker: a ÚNICA parte da extensão que conversa com a API.
// Por que não chamar a API direto do content script? Porque ele roda dentro da
// página do LinkedIn e esbarraria em CORS/mixed-content. Aqui, com
// host_permissions, a chamada para localhost é permitida.
//
// A chave da IA NUNCA fica na extensão — fica no servidor Ruby.
const API_URL = "http://localhost:9292";

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (message.type !== "suggest-comment") return false;

  fetch(`${API_URL}/comments/suggest`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ post: message.post }),
  })
    .then(async (res) => {
      const data = await res.json();
      sendResponse(res.ok ? { ok: true, data } : { ok: false, error: data.error });
    })
    .catch(() => sendResponse({ ok: false, error: "API offline? Rode `bundle exec rackup -p 9292`." }));

  return true; // mantém o canal aberto para a resposta assíncrona
});
