// Post Creator popup: collects the brief, asks background.js to call the API,
// shows an editable result with alternative hooks and an engagement checklist.
// It never publishes — you copy and paste it yourself.

const form = document.getElementById("brief-form");
const button = document.getElementById("generate");
const status = document.getElementById("status");
const result = document.getElementById("result");
const bodyField = document.getElementById("body");
const hashtagsField = document.getElementById("hashtags");
const hooksBlock = document.getElementById("hooks-block");
const hooksList = document.getElementById("hooks");
const checksList = document.getElementById("checks");
const copyButton = document.getElementById("copy");

const FIELDS = ["idea", "goal", "topics", "audience", "tone"];

// Remember the last brief and draft: popups close as soon as you click away.
chrome.storage.local.get(["lastBrief", "lastDraft"]).then(({ lastBrief, lastDraft }) => {
  FIELDS.forEach((name) => {
    if (lastBrief?.[name]) form.elements[name].value = lastBrief[name];
  });
  if (lastDraft) {
    showResult(lastDraft, "Your last draft. Edit it or write a new one.");
    recheck();
  }
});

form.addEventListener("submit", (event) => {
  event.preventDefault();

  const values = Object.fromEntries(FIELDS.map((name) => [name, form.elements[name].value.trim()]));
  chrome.storage.local.set({ lastBrief: values });

  const brief = {
    idea: values.idea,
    ...(values.goal && { goal: values.goal }),
    topics: values.topics.split(",").map((t) => t.trim()).filter(Boolean),
    ...(values.audience && { audience: values.audience }),
    ...(values.tone && { tone: values.tone }),
  };

  setBusy(true, "Writing your post… (a local model on CPU can take 1–3 minutes)");
  chrome.runtime.sendMessage({ type: "generate-post", brief }, (response) => {
    if (response?.ok) {
      const draft = { body: response.data.body, hashtags: response.data.hashtags, hooks: response.data.hooks ?? [], checks: response.data.checks ?? [] };
      showResult(draft, "Done. Edit anything before copying.");
      saveDraft();
      button.disabled = false;
    } else {
      setBusy(false, `⚠️ ${response?.error ?? "unknown error"}`);
    }
  });
});

function showResult(draft, message) {
  bodyField.value = draft.body;
  hashtagsField.value = (draft.hashtags ?? []).join(" ");
  renderHooks(draft.hooks ?? []);
  renderChecks(draft.checks ?? []);
  result.hidden = false;
  status.textContent = message;
}

// Alternative first lines: "Use" swaps the post's first line for the chosen hook.
function renderHooks(hooks) {
  hooksList.replaceChildren();
  hooksBlock.hidden = hooks.length === 0;
  hooks.forEach((hook) => {
    const item = document.createElement("li");
    const text = document.createElement("span");
    text.textContent = hook;
    const use = document.createElement("button");
    use.type = "button";
    use.className = "small";
    use.textContent = "Use";
    use.setAttribute("aria-label", `Use this opening: ${hook}`);
    use.addEventListener("click", () => {
      const [, ...rest] = bodyField.value.split("\n");
      bodyField.value = [hook, ...rest].join("\n");
      recheck();
      bodyField.focus();
    });
    item.append(text, use);
    hooksList.append(item);
  });
}

function renderChecks(checks) {
  checksList.replaceChildren();
  checks.forEach((check) => {
    const item = document.createElement("li");
    item.className = check.passed ? "pass" : "fail";
    const mark = document.createElement("span");
    mark.className = "mark";
    mark.textContent = check.passed ? "✓" : "✗";
    mark.setAttribute("aria-label", check.passed ? "passed" : "needs work");
    const label = document.createElement("span");
    label.textContent = check.label;
    item.append(mark, label);
    if (check.tip) {
      const tip = document.createElement("small");
      tip.textContent = check.tip;
      item.append(tip);
    }
    checksList.append(item);
  });
}

// Re-run the checklist as you edit. The API applies rules only (no AI), so it is instant.
let recheckTimer;
function recheck() {
  saveDraft();
  clearTimeout(recheckTimer);
  recheckTimer = setTimeout(() => {
    chrome.runtime.sendMessage(
      { type: "check-post", body: bodyField.value, hashtags: currentHashtags() },
      (response) => { if (response?.ok) renderChecks(response.data); }
    );
  }, 600);
}

bodyField.addEventListener("input", recheck);
hashtagsField.addEventListener("input", recheck);

function currentHashtags() {
  return hashtagsField.value.split(/\s+/).filter(Boolean);
}

function saveDraft() {
  const hooks = [...hooksList.querySelectorAll("li > span")].map((s) => s.textContent);
  chrome.storage.local.set({ lastDraft: { body: bodyField.value, hashtags: currentHashtags(), hooks, checks: [] } });
}

copyButton.addEventListener("click", async () => {
  const text = [bodyField.value.trim(), hashtagsField.value.trim()].filter(Boolean).join("\n\n");
  await navigator.clipboard.writeText(text);
  status.textContent = "Copied to clipboard.";
});

function setBusy(busy, message) {
  button.disabled = busy;
  status.textContent = message;
}
