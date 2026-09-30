// O LinkedIn muda as classes do HTML com frequência.
// Por isso TODOS os seletores moram aqui: quando quebrar, você conserta um
// arquivo só. É o mesmo princípio do adapter de LLM, aplicado ao DOM.
//
// ⚠️ Confira no DevTools (Inspecionar elemento) antes de usar — estes são um
// ponto de partida, não uma garantia.
const LP_SELECTORS = {
  post: "div.feed-shared-update-v2",
  text: ".update-components-text, .feed-shared-inline-show-more-text",
  author: ".update-components-actor__title span[aria-hidden='true'], .update-components-actor__name",
  permalink: "a[href*='/feed/update/']",
};
