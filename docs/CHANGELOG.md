# Changelog

Where the code changed, and why — one section per step, newest first.
Paths are relative to the repository root. See [ROADMAP](ROADMAP.md) for what comes next.

## 0.6.1 — Slow local models: clear timeout and faster posts

**Why:** on CPU, Ollama took longer than 180 s to write a post and the popup only said
`network error calling ollama: Net::ReadTimeout`.

| Area | File | Change |
| --- | --- | --- |
| LLM | `lib/linkedin_poster/llm/http_transport.rb` | A read timeout now says how long we waited and what to do |
| Adapters | `lib/linkedin_poster/llm/adapters/ollama.rb` | `OLLAMA_TIMEOUT` (default 300 s); `keep_alive` (`OLLAMA_KEEP_ALIVE`, default 30m) keeps the model loaded between requests |
| Prompts | `lib/linkedin_poster/prompts/post_prompt_builder.rb` | `max_tokens` 1400 → 900: enough for the post, less waiting |
| Extension | `extension/popup.js`, `extension/content.js` | Honest waiting messages (1–3 minutes on CPU) |
| Config | `.env.example` | Documents the two new variables |
| Tests | `test/llm/adapters_test.rb` | Timeout produces the explained error |

## 0.6.0 — New LinkedIn feed selectors and Post Creator v2 (engagement)

**Why:** the "Suggest comment" button never showed up on the real feed. LinkedIn moved to new
markup with random CSS classes, so `div.feed-shared-update-v2` matched **0** posts. The Post Creator
needed to start from what *you* want to say and to aim for posts people answer.

| Area | File | Change |
| --- | --- | --- |
| Extension | `extension/selectors.js` | Current feed first (`[role="listitem"][componentkey^="update-card"]`, `[data-testid="expandable-text-box"]`), old feed as fallback; author read from the "…" menu's `aria-label` |
| Extension | `extension/content.js` | `findAuthor()` handles both markups |
| Extension | `extension/content.css` | Button no longer stretches full width; translucent colors work in LinkedIn's dark theme |
| Extension | `extension/popup.html`, `popup.js`, `popup.css` | **"What do you want to say?"** is the main field; Goal is a short list; topics/audience/tone under "More options"; alternative hooks with "Use"; live engagement checklist; last draft is remembered |
| Extension | `extension/background.js`, `dev/feed.html` | New `check-post` route; dev feed gains a post with the new LinkedIn markup |
| Extension | `extension/manifest.json` | Version 0.3.0 |
| Domain | `lib/linkedin_poster/domain/post_brief.rb` | New `idea`; needs an idea **or** a goal; topics are optional |
| Domain | `lib/linkedin_poster/domain/generated_post.rb` | New `hooks` and `checks`; `to_h` serializes the checks |
| Text rules | `lib/linkedin_poster/text/engagement_check.rb` | **New.** Checklist without AI: hook ≤ 150 chars, closing question, short paragraphs, 600–1300 chars, no links, 3–5 hashtags, no engagement bait |
| Prompts | `lib/linkedin_poster/prompts/post_prompt_builder.rb` | v3: the idea is the core; engagement rules; 2 alternative hooks; writes in the idea's language |
| Services | `lib/linkedin_poster/services/generate_post.rb` | Detects the idea's language, cleans hooks, runs the checklist |
| LLM | `lib/linkedin_poster/llm/adapters/fake.rb` | Offline answer includes hooks and a closing question |
| HTTP | `app/controllers/posts_controller.rb`, `config/routes.rb` | Accepts `idea`; **new** `POST /posts/check` (rules only, instant) |
| Prompt Lab | `bin/prompt-lab`, `prompt_lab/posts.yml` | Post cases start from an idea (one in Portuguese, one goal-only); every case is scored by the engagement checklist |
| Tests | `test/text/engagement_check_test.rb` | **New.** One test per rule |
| Tests | `test/services/services_test.rb`, `test/integration/api_test.rb` | Idea-or-goal rule, idea in the prompt + language, hooks/checks, `/posts/check` |

## 0.5.0 — Prompt v2 and Phase 2 dev feed

**Why:** the first real-AI run (Ollama) passed every automatic check but replied in the wrong
language, invented experience and opened with "Interesting!". Phase 2 needed a way to test the
extension without depending on LinkedIn's HTML.

| Area | File | Change |
| --- | --- | --- |
| Text rules | `lib/linkedin_poster/text/language_detector.rb` | **New.** Detects the post's language (en/pt) by counting common words; returns `nil` when unsure |
| Domain | `lib/linkedin_poster/domain/user_profile.rb` | New `highlights` field: true facts from the resume, the only experience the AI may cite. Default language `en-US` |
| Prompts | `lib/linkedin_poster/prompts/comment_prompt_builder.rb` | v2: write in the post's language, cite only highlights, no opening interjection, `angle` always in English |
| Prompts | `lib/linkedin_poster/prompts/post_prompt_builder.rb` | v2: use only highlights for experience and stories |
| Services | `lib/linkedin_poster/services/suggest_comment.rb` | Asks the detector for the post's language and passes it to the prompt (falls back to the profile's) |
| Loader | `lib/linkedin_poster.rb` | Requires the language detector |
| Config | `config/profile.example.yml` | Explains that the profile is written from the resume; example `highlights` |
| Prompt Lab | `bin/prompt-lab` | New checks: "no opening interjection" and "same language as post"; checks now receive the test case |
| Prompt Lab | `prompt_lab/comments.yml` | Expectations rewritten around language and real facts |
| HTTP | `app/controllers/dev_controller.rb` | **New.** Development-only: serves the dev feed and a whitelist of extension files |
| HTTP | `config/routes.rb` | `/dev/feed` and `/dev/extension/:file`, development only |
| Extension | `extension/dev/feed.html` | **New.** Fake posts with LinkedIn's markup + a `chrome.runtime` shim, so the real `content.js` runs locally |
| Extension | `extension/content.js` | English UI; button disabled while writing; "Try again" on errors; "Another one" to regenerate; ARIA labels |
| Extension | `extension/content.css` | Styles for the new panel states and focus rings |
| Tests | `test/text/language_detector_test.rb` | **New.** Detector + "English post gets English prompt" + "highlights are the only citable facts" |
| Tests | `test/test_helper.rb` | Test profile gains `highlights` |
| Docs | `README.md`, `docs/ROADMAP.md` | Dev feed instructions; Phase 0.5 and 1 done, Phase 2 in progress |

Private, not in git: `config/profile.yml` rewritten from the resume (11 highlights, `job_targets`, headline).

## 0.4.0 — Prompt Lab and Ollama

**Why:** tune prompts with evidence instead of guesswork, and run a real AI locally for free.

| Area | File | Change |
| --- | --- | --- |
| Tooling | `bin/prompt-lab` | **New.** Runs an evaluation set against the configured AI, checks rules, saves a report per version |
| Tooling | `prompt_lab/comments.yml`, `prompt_lab/posts.yml` | **New.** Realistic cases with "what good looks like" |
| Adapters | `lib/linkedin_poster/llm/adapters/ollama.rb` | Forces JSON output (`format: "json"`); documents which `OLLAMA_URL` to use |
| Prompts | `lib/linkedin_poster/prompts/*_prompt_builder.rb` | `VERSION` constant so reports can be compared |
| Docker | `compose.yaml` | `extra_hosts: host.docker.internal` so the container can reach services on your machine |
| Tests | `test/llm/adapters_test.rb` | Adapter tests no longer depend on `.env` (explicit URLs) |
| Config | `.env.example`, `.gitignore` | Which `OLLAMA_URL` to pick; ignore `prompt_lab/runs/` |

## 0.3.0 — Job-focused ranking, Post Creator popup, English messages

**Why:** "best posts" means posts about the jobs you want to apply for; the Post Creator lives in the extension.

| Area | File | Change |
| --- | --- | --- |
| Domain | `lib/linkedin_poster/domain/job_target.rb` | **New.** A target job plus the words recruiters use for it |
| Domain | `lib/linkedin_poster/domain/user_profile.rb` | `job_targets` (still accepts the old `target_roles`) |
| Domain | `lib/linkedin_poster/domain/ranked_post.rb` | `job_opening`, `matched_targets`, human-readable `reason` |
| Services | `lib/linkedin_poster/services/rank_posts.rb` | +3 per target, +5 if it is a hiring post for a target, +1 per keyword |
| Core | domain, adapters, parser, transport | Error messages translated to English |
| Extension | `extension/popup.html`, `popup.js`, `popup.css` | **New.** Post Creator popup |
| Extension | `extension/background.js` | Single message router for all API calls |
| Extension | `extension/manifest.json` | Registers the popup |
| Tests | `test/services/rank_posts_test.rb` | **New.** Ranking rules |

## 0.2.0 — Sinatra → Rails 8 API

**Why:** familiar framework, ActiveRecord ready for Phase 5. Only the HTTP layer changed ([ADR-0002](adr/0002-rails-as-the-http-layer.md)).

| Area | File | Change |
| --- | --- | --- |
| HTTP | `app/api.rb` | **Removed** (Sinatra) |
| HTTP | `app/controllers/*.rb` | **New.** `ApplicationController` (error → HTTP status), `Health`, `Comments`, `Posts` |
| Rails | `config/application.rb`, `boot.rb`, `environment.rb`, `environments/*`, `routes.rb`, `config.ru`, `bin/rails` | **New.** Minimal API-only Rails app |
| Rails | `config/initializers/linkedin_poster.rb` | **New.** Composition root: picks the AI and loads the profile |
| Build | `Gemfile`, `Dockerfile` | Rails instead of Sinatra; server started with `bin/rails server` |
| Tests | `test/integration/api_test.rb` | **New.** Endpoint tests with the Fake AI |

## 0.1.0 — Initial architecture

**Why:** a plain-Ruby core with the AI behind a port, so the provider can change without touching
business rules ([ADR-0001](adr/0001-ruby-core-with-ports-and-adapters.md)).

| Area | Files | What |
| --- | --- | --- |
| Domain | `lib/linkedin_poster/domain/*` | Immutable value objects with validation |
| LLM | `lib/linkedin_poster/llm/*` | Port, Anthropic/OpenAI/Ollama/Fake adapters, registry, HTTP transport, errors |
| Text | `lib/linkedin_poster/text/*` | Keywords, hashtags, JSON response parser |
| Prompts / Services | `lib/linkedin_poster/prompts/*`, `services/*` | Prompt builders; SuggestComment, GeneratePost, RankPosts |
| Extension | `extension/*` | Content script, selectors, background worker |
| Environment | `Dockerfile`, `compose.yaml`, `bin/smoke`, `.env.example` | Docker, offline mode, smoke test |
| Docs | `README.md`, `docs/ROADMAP.md`, `docs/adr/0001-*` | Architecture, roadmap, first ADR |
