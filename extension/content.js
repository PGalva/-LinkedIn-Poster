// Content script: runs inside LinkedIn. Its only jobs:
//   1. find posts on screen         -> collectPost()
//   2. add a button to each one     -> attachButton()
//   3. show the suggestion          -> renderPanel()
//   4. badge the posts that help you get seen by people who hire -> queueRank() / renderBadge()
//
// Key decision: the extension NEVER publishes the comment by itself.
// It suggests, you edit and paste. Full automation violates LinkedIn's Terms
// and can restrict your account — exactly when you are job hunting.
//
// The same file runs in the local dev feed (http://localhost:9292/dev/feed),
// where a small shim replaces chrome.runtime. See extension/dev/feed.html.

function collectPost(postEl) {
  const text = postEl.querySelector(LP_SELECTORS.text)?.innerText?.trim() ?? "";
  const url = postEl.querySelector(LP_SELECTORS.permalink)?.href ?? location.href;
  const author = findAuthor(postEl);
  return { text, author, author_headline: findAuthorHeadline(postEl, author), url };
}

// Lines as LinkedIn renders them; "• 3rd+" style suffixes are cut off.
function postLines(text) {
  return text.split("\n").map((l) => l.replace(/^•\s*/, "").split(/\s+•\s+/)[0].trim()).filter(Boolean);
}

// The line under the author's name ("Design Manager at Acme"). It tells recruiters and
// hiring managers apart from peers. null for company pages or when it can't be found.
function findAuthorHeadline(postEl, author) {
  const old = postEl.querySelector(LP_SELECTORS.authorHeadline)?.innerText?.trim();
  if (old) return old;
  if (!author) return null;

  const all = postLines(postEl.innerText);
  const box = postEl.querySelector(LP_SELECTORS.text);
  const stop = box ? all.indexOf(postLines(box.innerText)[0]) : -1;
  const header = stop > 0 ? all.slice(0, stop) : all;
  const at = header.lastIndexOf(author);
  if (at < 0) return null;

  const after = header.slice(at + 1);
  if (after.some((l) => LP_SELECTORS.headerFollowers.test(l))) return null; // a company page
  return after.find((l) => l !== author && !LP_SELECTORS.headerNoise.test(l) && !LP_SELECTORS.headerTime.test(l)) ?? null;
}

// Current feed: the author's name only appears reliably in the "…" menu's aria-label.
// Old feed: it has its own element.
function findAuthor(postEl) {
  const label = postEl.querySelector(LP_SELECTORS.authorMenu)?.getAttribute("aria-label");
  if (label) return label.replace(LP_SELECTORS.authorMenuPrefix, "").trim() || null;
  return postEl.querySelector(LP_SELECTORS.author)?.innerText?.trim() || null;
}

function renderPanel(postEl, { loading, text, angle, error, onRetry }) {
  let panel = postEl.querySelector(".lp-panel");
  if (!panel) {
    panel = document.createElement("div");
    panel.className = "lp-panel";
    panel.setAttribute("role", "region");
    panel.setAttribute("aria-label", "Comment suggestion");
    postEl.appendChild(panel);
  }
  panel.replaceChildren();

  if (loading) {
    const status = document.createElement("p");
    status.setAttribute("role", "status");
    status.textContent = "Writing a comment… (a local model on CPU can take 1–2 minutes)";
    panel.append(status);
    return;
  }

  if (error) {
    const message = document.createElement("p");
    message.setAttribute("role", "alert");
    message.textContent = `⚠️ ${error}`;
    const retry = document.createElement("button");
    retry.type = "button";
    retry.textContent = "Try again";
    retry.addEventListener("click", onRetry);
    panel.append(message, retry);
    return;
  }

  const area = document.createElement("textarea");
  area.value = text;
  area.rows = 4;
  area.setAttribute("aria-label", "Suggested comment (editable)");

  const meta = document.createElement("p");
  meta.className = "lp-meta";
  meta.textContent = angle ? `Angle: ${angle} · review before posting` : "Review before posting";

  const actions = document.createElement("div");
  actions.className = "lp-actions";

  const another = document.createElement("button");
  another.type = "button";
  another.textContent = "Another one";
  another.addEventListener("click", onRetry);

  const copy = document.createElement("button");
  copy.type = "button";
  copy.textContent = "Copy";
  copy.addEventListener("click", async () => {
    await navigator.clipboard.writeText(area.value);
    copy.textContent = "Copied ✓";
  });

  actions.append(another, copy);
  panel.append(area, meta, actions);
}

function suggest(postEl, button) {
  const post = collectPost(postEl);
  if (!post.text) {
    renderPanel(postEl, {
      error: "Couldn't find this post's text (LinkedIn may have changed its HTML — check selectors.js).",
      onRetry: () => suggest(postEl, button),
    });
    return;
  }

  button.disabled = true;
  renderPanel(postEl, { loading: true });

  chrome.runtime.sendMessage({ type: "suggest-comment", post }, (response) => {
    button.disabled = false;
    if (response?.ok) {
      renderPanel(postEl, {
        text: response.data.text,
        angle: response.data.angle,
        onRetry: () => suggest(postEl, button),
      });
    } else {
      renderPanel(postEl, {
        error: response?.error ?? "unknown error",
        onRetry: () => suggest(postEl, button),
      });
    }
  });
}

function attachButton(postEl) {
  if (postEl.dataset.lpReady) return;
  // Only real posts with text: skips cards like "Who viewed your profile" or job anniversaries.
  // Not marked as ready, so a post whose text loads later is picked up by the next scan.
  if (!postEl.querySelector(LP_SELECTORS.text)) return;
  postEl.dataset.lpReady = "1";

  const button = document.createElement("button");
  button.type = "button";
  button.className = "lp-button";
  button.textContent = "💡 Suggest comment";
  button.addEventListener("click", () => suggest(postEl, button));

  postEl.prepend(button);
  queueRank(postEl);
}

// ---- Ranking badges (rules only, no AI: instant and free) ----
// New posts are sent in small batches to /posts/rank; the ones that score get a badge
// explaining why ("Hiring manager · Vancouver · UI/UX Design").
const rankQueue = [];
let rankTimer;

function queueRank(postEl) {
  const post = collectPost(postEl);
  if (!post.text) return;
  rankQueue.push({ el: postEl, post });
  clearTimeout(rankTimer);
  rankTimer = setTimeout(flushRank, 800);
}

function flushRank() {
  const batch = rankQueue.splice(0, 20);
  if (batch.length === 0) return;

  chrome.runtime.sendMessage({ type: "rank-posts", posts: batch.map((b) => b.post), limit: batch.length }, (response) => {
    // Badges are a bonus: if the API is offline we stay quiet (the 💡 button shows the error).
    if (response?.ok) {
      const byText = new Map(batch.map((b) => [b.post.text, b.el]));
      response.data.forEach((ranked) => {
        const el = byText.get(ranked.post.text);
        if (el) renderBadge(el, ranked);
      });
    }
    if (rankQueue.length) flushRank();
  });
}

function renderBadge(postEl, ranked) {
  postEl.querySelector(".lp-badge")?.remove();
  const hirer = ["recruiter", "hiring_manager"].includes(ranked.author_type);
  const icon = hirer ? "🎯" : ranked.job_opening ? "💼" : "✨";

  const badge = document.createElement("p");
  badge.className = `lp-badge${hirer || ranked.job_opening ? " lp-badge--high" : ""}`;
  badge.textContent = `${icon} ${ranked.reason}`;
  badge.title = `Why this post: score ${ranked.score} (rules in RankPosts, no AI)`;
  postEl.querySelector(".lp-button")?.after(badge);
}

// The feed loads posts as you scroll, so we watch the DOM for new ones.
// Debounced: LinkedIn fires hundreds of mutations per second; scan at most every 500ms.
const scan = () => document.querySelectorAll(LP_SELECTORS.post).forEach(attachButton);
let scanTimer;
new MutationObserver(() => {
  clearTimeout(scanTimer);
  scanTimer = setTimeout(scan, 500);
}).observe(document.body, { childList: true, subtree: true });
scan();
