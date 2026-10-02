# Roadmap

The core is built and tested, the HTTP layer now runs on Rails, the feed ranking targets the jobs you
want to apply for, and the Post Creator lives in the extension popup. Next up: running everything on a
real machine (Phase 0.5) and the first comment from the real Claude API (Phase 1).

Each phase is a **vertical slice**: it delivers something that works end to end before the next one starts.

| Phase | Deliverable | Status |
| --- | --- | --- |
| 0 | Ruby core, AI adapters, tests | Done |
| 0.5 | Environment: Docker, Rails, offline mode, smoke test | In progress |
| 1 | Comment suggestions with a real AI + prompt tuning | In progress |
| 2 | Chrome extension in the feed | Not started |
| 3 | Post Creator (extension popup) | Built, needs a real run |
| 4 | Job-focused feed ranking | Backend done, extension pending |
| 5 | History (ActiveRecord + SQLite) and metrics | Not started |

## Phases and tasks

### Phase 0 — Core

Done when: `rake test` passes with no internet connection.

- [x] Immutable domain objects (`Data.define`) with validation
- [x] LLM port + Anthropic, OpenAI, Ollama and Fake adapters
- [x] Contract test every adapter must pass
- [x] Keywords, hashtags and JSON parser (no AI involved)
- [x] SuggestComment, GeneratePost and RankPosts services

Lesson: the core knows nothing about frameworks or AI providers, which is why it tests in milliseconds.

### Phase 0.5 — Environment

Done when: all endpoints respond with `LLM_PROVIDER=fake`, without an API key or internet.

- [x] Dockerfile and compose.yaml
- [x] Fake adapter produces valid responses for comments and posts
- [x] Smoke test script (`bin/smoke`)
- [x] HTTP layer moved from Sinatra to Rails 8 API ([ADR-0002](adr/0002-rails-as-the-http-layer.md))
- [x] Rails integration tests for every endpoint
- [ ] `docker compose build` and `docker compose run --rm api bundle exec rake test` pass locally
- [ ] `bash bin/smoke` passes against the running API

Lesson: switching Sinatra for Rails touched only the HTTP layer — the core and its tests didn't change.

### Phase 1 — Comments with real Claude

Done when: 5 real posts get comments you would publish with little or no editing.

- [x] Prompt Lab (`bin/prompt-lab`): evaluation set + automatic rule checks + versioned reports
- [x] Ollama adapter forces JSON output (`format: "json"`)
- [ ] Run the Prompt Lab on Ollama and record the v1 baseline
- [ ] Tune `comment_prompt_builder.rb` one change at a time (bump `VERSION`, compare reports)
- [ ] Add 5 real posts from the feed to `prompt_lab/comments.yml` (include 2 job openings)
- [ ] Re-run the final version on Claude (`LLM_PROVIDER=anthropic`) to compare quality

Lesson: prompts are code. They change through review and tests, not ad hoc.

### Phase 2 — Extension in the feed

Done when: the button shows up on posts, the suggestion arrives and "Copy" works.

- [ ] Load `extension/` in `chrome://extensions`
- [ ] Verify selectors in DevTools and fix `selectors.js`
- [ ] Handle visible errors: API offline, post without text, AI rate limit
- [ ] Local test page with fake posts (for offline testing)

Lesson: LinkedIn's DOM is an unstable external "provider", isolated in a single file.

### Phase 3 — Post Creator (popup)

Done when: the popup generates a post + hashtags and you can copy it in one click.

- [x] Decision: popup inside the extension
- [x] Form with Goal, Topics, Audience and Tone; remembers the last brief
- [x] Calls `/posts/generate` through `background.js`; editable body and hashtags; Copy button
- [ ] Try it with the API running and a real AI provider
- [ ] Optional: move to React + Vite if the popup grows past one form

Lesson: plain HTML/JS needs no build step; add tooling only when the UI earns it.

### Phase 4 — Job-focused feed ranking

Done when: posts about the jobs you want (UI/UX Design, Co-op, Developer) are highlighted in the feed,
hiring posts first.

- [x] `job_targets` in the profile, each with the terms recruiters use
- [x] Scoring: +3 per target, +5 if it is a hiring post for a target, +1 per keyword
- [x] Hiring signals in English and Portuguese
- [x] `reason` explains each score ("Job opening · UI/UX Design, Co-op")
- [ ] Extension sends visible posts to `/posts/rank` and highlights the top ones with their reason
- [ ] Calibrate terms and weights with real feed posts

### Phase 5 — History and metrics

Done when: you can see what was suggested, what you published and what got engagement.

- [ ] Add ActiveRecord + SQLite; suggestions and publications tables
- [ ] "I published this" action in the extension
- [ ] Simple dashboard: comments per week, replies received, job posts engaged with

## Testing

Three of the four test levels work fully offline; only the last one needs internet and an API key.

| Level | Offline? | Command | What it proves |
| --- | --- | --- | --- |
| Unit + integration tests | Yes | `docker compose run --rm api bundle exec rake test` | Rules, prompts, adapters and endpoints are correct (simulated AI) |
| API with Fake | Yes | `LLM_PROVIDER=fake`, `docker compose up`, then `bash bin/smoke` | The running server works end to end |
| API with Ollama | Yes, after the model download | `LLM_PROVIDER=ollama`, `docker compose --profile ollama up -d`, `docker compose exec ollama ollama pull llama3.1` | Real AI output, local and free |
| API with Claude | No | `LLM_PROVIDER=anthropic` + `ANTHROPIC_API_KEY` | Final comment quality |

## Decisions

| Decision | Choice | Why |
| --- | --- | --- |
| Isolate the AI ([ADR-0001](adr/0001-ruby-core-with-ports-and-adapters.md)) | Ports & adapters; switch via `LLM_PROVIDER` | Swap Claude for another AI without touching services |
| HTTP framework ([ADR-0002](adr/0002-rails-as-the-http-layer.md)) | Rails 8, API only | Familiar, and ActiveRecord is ready for Phase 5 |
| Who captures the post | The extension, from the open page | LinkedIn requires login; the server can't read the URL |
| Publishing | Suggest only; the user reviews and publishes | Full automation violates LinkedIn's Terms and risks the account |
| What "best posts" means | Posts about the jobs you want, hiring posts first | The goal is applying, not general engagement |
| Post Creator location | Extension popup | One install, available on any page |

## Risks

| Risk | Mitigation |
| --- | --- |
| LinkedIn changes its selectors | All in `selectors.js`; the extension warns when it can't find the text |
| Generic comments sound like a bot | Prompt bans empty praise; the user reviews before publishing |
| Ranking misses job posts worded differently | Terms are editable per target in `profile.yml`; calibrate in Phase 4 |
| AI costs go up | Ranking uses no AI; Ollama for development; provider switch by config |
| Prompt injection in post text | Post is wrapped in `<post>` and the prompt treats it as data only |

## Ideas beyond Phase 5

- Suggest 2–3 comment angles to choose from
- Schedule posts for peak reach times
- Follow specific recruiters and prioritize their posts
- Use the AI as a second pass to classify ambiguous job posts the rules miss
