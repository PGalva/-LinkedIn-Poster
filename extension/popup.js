// Post Creator popup: collects the brief, asks background.js to call the API,
// shows an editable result. It never publishes — you copy and paste it yourself.

const form = document.getElementById("brief-form");
const button = document.getElementById("generate");
const status = document.getElementById("status");
const result = document.getElementById("result");
const bodyField = document.getElementById("body");
const hashtagsField = document.getElementById("hashtags");
const copyButton = document.getElementById("copy");

const FIELDS = ["goal", "topics", "audience", "tone"];

// Remember the last brief: popups close as soon as you click away.
chrome.storage.local.get("lastBrief").then(({ lastBrief }) => {
  if (!lastBrief) return;
  FIELDS.forEach((name) => {
    if (lastBrief[name]) form.elements[name].value = lastBrief[name];
  });
});

form.addEventListener("submit", (event) => {
  event.preventDefault();

  const values = Object.fromEntries(FIELDS.map((name) => [name, form.elements[name].value.trim()]));
  chrome.storage.local.set({ lastBrief: values });

  const brief = {
    goal: values.goal,
    topics: values.topics.split(",").map((t) => t.trim()).filter(Boolean),
    ...(values.audience && { audience: values.audience }),
    ...(values.tone && { tone: values.tone }),
  };

  setBusy(true, "Writing your post…");
  chrome.runtime.sendMessage({ type: "generate-post", brief }, (response) => {
    if (response?.ok) {
      bodyField.value = response.data.body;
      hashtagsField.value = response.data.hashtags.join(" ");
      result.hidden = false;
      setBusy(false, "Done. Edit anything before copying.");
    } else {
      setBusy(false, `⚠️ ${response?.error ?? "unknown error"}`);
    }
  });
});

copyButton.addEventListener("click", async () => {
  const text = [bodyField.value.trim(), hashtagsField.value.trim()].filter(Boolean).join("\n\n");
  await navigator.clipboard.writeText(text);
  status.textContent = "Copied to clipboard.";
});

function setBusy(busy, message) {
  button.disabled = busy;
  status.textContent = message;
}
