// LinkedIn changes its HTML often, so EVERY selector lives here: when the feed
// breaks, you fix one file. Same principle as the LLM adapters, applied to the DOM.
//
// Each entry lists the current markup first and older markup after it, so the
// extension keeps working on accounts that still get the old feed (and on the
// local dev feed).
//
// How to re-check them: open the feed, F12 → Console, and run
//   document.querySelectorAll(LP_SELECTORS.post).length   // should be > 0
//
// Oct 2026 feed: CSS classes are random (e.g. "ckymvu ckytj") and change on every
// deploy, so we only rely on stable hooks: role, componentkey, data-testid, aria-label.
const LP_SELECTORS = {
  post: [
    '[role="listitem"][componentkey^="update-card"]', // current feed
    "div.feed-shared-update-v2",                      // old feed + dev feed
  ].join(", "),

  text: [
    '[data-testid="expandable-text-box"]',
    ".update-components-text, .feed-shared-inline-show-more-text",
  ].join(", "),

  // The post's "…" menu button is labelled with the author's name:
  // "Abrir menu de controle da publicação de Maya Chen" / "Open control menu for post by Maya Chen"
  authorMenu: 'button[aria-label^="Abrir menu de controle da publicação de"], button[aria-label^="Open control menu for post by"]',
  authorMenuPrefix: /^(Abrir menu de controle da publicação de|Open control menu for post by)\s+/,

  author: ".update-components-actor__title span[aria-hidden='true'], .update-components-actor__name",
  permalink: "a[href*='/feed/update/']",
};
