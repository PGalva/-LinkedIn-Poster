// Content script: roda dentro do LinkedIn. Responsabilidades (e só estas):
//   1. achar posts na tela       -> collectPost()
//   2. pôr um botão em cada um   -> attachButton()
//   3. mostrar a sugestão        -> renderPanel()
//
// Decisão importante: a extensão NÃO publica o comentário sozinha.
// Ela sugere, você edita e cola. Automação total viola os Termos do LinkedIn
// e pode restringir sua conta — justamente quando você está buscando vaga.

function collectPost(postEl) {
  const text = postEl.querySelector(LP_SELECTORS.text)?.innerText?.trim() ?? "";
  const author = postEl.querySelector(LP_SELECTORS.author)?.innerText?.trim() ?? null;
  const url = postEl.querySelector(LP_SELECTORS.permalink)?.href ?? location.href;
  return { text, author, url };
}

function renderPanel(postEl, { loading, text, error }) {
  let panel = postEl.querySelector(".lp-panel");
  if (!panel) {
    panel = document.createElement("div");
    panel.className = "lp-panel";
    postEl.appendChild(panel);
  }
  panel.replaceChildren();

  if (loading) {
    panel.textContent = "Pensando num comentário…";
    return;
  }
  if (error) {
    panel.textContent = `⚠️ ${error}`;
    return;
  }

  const area = document.createElement("textarea");
  area.value = text;
  area.rows = 4;

  const copy = document.createElement("button");
  copy.textContent = "Copiar";
  copy.addEventListener("click", async () => {
    await navigator.clipboard.writeText(area.value);
    copy.textContent = "Copiado ✓";
  });

  panel.append(area, copy);
}

function attachButton(postEl) {
  if (postEl.dataset.lpReady) return;
  postEl.dataset.lpReady = "1";

  const button = document.createElement("button");
  button.className = "lp-button";
  button.textContent = "💡 Sugerir comentário";
  button.addEventListener("click", () => {
    const post = collectPost(postEl);
    if (!post.text) return renderPanel(postEl, { error: "Não achei o texto deste post (seletor desatualizado?)" });

    renderPanel(postEl, { loading: true });
    chrome.runtime.sendMessage({ type: "suggest-comment", post }, (response) => {
      if (response?.ok) renderPanel(postEl, { text: response.data.text });
      else renderPanel(postEl, { error: response?.error ?? "erro desconhecido" });
    });
  });

  postEl.prepend(button);
}

// O feed carrega posts conforme você rola: observamos o DOM para pegar os novos.
// Debounce: o LinkedIn gera centenas de mutações por segundo; varremos no máximo a cada 500ms.
const scan = () => document.querySelectorAll(LP_SELECTORS.post).forEach(attachButton);
let scanTimer;
new MutationObserver(() => {
  clearTimeout(scanTimer);
  scanTimer = setTimeout(scan, 500);
}).observe(document.body, { childList: true, subtree: true });
scan();
