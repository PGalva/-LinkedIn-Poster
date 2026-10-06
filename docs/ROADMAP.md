# Roadmap

Everything runs locally with Docker and a local AI (Ollama). The extension works on the real feed
(new markup, Oct 2026): it suggests comments, badges the posts worth engaging with and knows who wrote
them (recruiter, hiring manager, field reference, peer). The Post Creator starts from your own idea.
Next: calibrate 4c with real use, then engagement signals (4b) and history (5).

Each phase is a **vertical slice**: it delivers something that works end to end before the next one starts.

| Phase | Deliverable | Status |
| --- | --- | --- |
| 0 | Ruby core, AI adapters, tests | Done |
| 0.5 | Environment: Docker, Rails, offline mode, smoke test | Done |
| 1 | Comment suggestions with a real AI + prompt tuning | Done (v2) |
| 2 | Chrome extension in the feed | In progress |
| 3 | Post Creator (extension popup) | v2 built (idea + engagement), needs a real run |
| 4 | Job-focused feed ranking | Done: badges in the feed (v0.7) |
| 4c | Audience targeting: who wrote it (recruiter, hiring manager, peer), locations, target companies | Done (v0.7) — calibrate with real use |
| 5 | History (ActiveRecord + SQLite) and metrics | Not started |
| 6 | Market insights: skill demand from job posts + profile audit | Proposed (needs Phase 5 storage) |
| 7 | Insight-driven post ideas | Proposed (needs Phase 6) |

**North star:** be seen by the people who can hire you. Everything from 4c to 7 serves it in three ways:
engage with the feed posts that put you in front of recruiters, hiring managers and the bubble of the
roles you want; post about what the market asks for; and be findable in recruiter search.

**Where data comes from:** only pages *you* open on LinkedIn (feed, job pages, your own profile).
The extension reads what is on your screen; it never browses, crawls or acts on its own.

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
- [x] Run the Prompt Lab on Ollama and record the v1 baseline (rules 7/7, but replied in the wrong
      language, invented experience and opened with "Interesting!")
- [x] Prompt v2: reply in the post's language (`Text::LanguageDetector`), cite ONLY profile
      `highlights` (taken from the resume), no opening interjection
- [x] Prompt Lab checks for "no opening interjection" and "same language as post"
- [x] Run the v2 lab on Ollama: 52/54 checks, right language in every case, no invented projects
- [ ] v3 candidates: one case stretched a fact ("designing systems" for backend work); a job post got
      one sentence with no link to the profile; "Great to see…" opener (now caught by the lab)
- [ ] Add 5 real posts from the feed to `prompt_lab/comments.yml` (include 2 job openings)
- [ ] Re-run the final version on Claude (`LLM_PROVIDER=anthropic`) to compare quality

Lesson: prompts are code. They change through review and tests, not ad hoc.

### Phase 2 — Extension in the feed

Done when: the button shows up on posts, the suggestion arrives and "Copy" works.

- [x] Local dev feed with LinkedIn-like markup: `http://localhost:9292/dev/feed` (development only)
- [x] Visible errors with "Try again"; button disabled while the AI is writing; "Another one" to regenerate
- [x] Verify selectors against the real feed: LinkedIn moved to random CSS classes; now using
      `role`, `componentkey`, `data-testid` and `aria-label` (old markup kept as fallback)
- [x] Dev feed includes a post with the new markup
- [ ] Load `extension/` with **Load unpacked** (not "Pack extension") and get a real suggestion

Lesson: LinkedIn's DOM is an unstable external "provider", isolated in a single file.

### Phase 3 — Post Creator (popup)

Done when: the popup generates a post + hashtags and you can copy it in one click.

- [x] Decision: popup inside the extension
- [x] Form with Goal, Topics, Audience and Tone; remembers the last brief
- [x] Calls `/posts/generate` through `background.js`; editable body and hashtags; Copy button
- [x] v2: "What do you want to say?" is the main input; goal is optional; topics/audience/tone under "More options"
- [x] Prompt v3: hook under 150 chars, one idea, closing question, no links, 2 alternative hooks
- [x] Engagement checklist without AI (`Text::EngagementCheck`), re-checked live via `POST /posts/check`
- [ ] Run `bin/prompt-lab posts` on Ollama and record the v3 baseline
- [ ] Try it with the API running and a real AI provider
- [ ] Optional: move to React + Vite if the popup grows past one form

Lesson: plain HTML/JS needs no build step; add tooling only when the UI earns it. And: the AI writes,
rules review — the checklist is instant, free and testable.

### Phase 4 — Job-focused feed ranking

Done when: posts about the jobs you want (UI/UX Design, Co-op, Developer) are highlighted in the feed,
hiring posts first.

- [x] `job_targets` in the profile, each with the terms recruiters use
- [x] Scoring: +3 per target, +5 if it is a hiring post for a target, +1 per keyword
- [x] Hiring signals in English and Portuguese
- [x] `reason` explains each score ("Job opening · UI/UX Design, Co-op")
- [x] Extension sends visible posts to `/posts/rank` and badges the ones that score, with their reason
- [ ] Calibrate terms and weights with real feed posts

### Phase 4b — Engagement signals (proposed)

Done when: ranking favours posts where a comment will actually be seen, and suggestions avoid
repeating what top comments already said.

- [ ] Capture what is already on screen: reactions, comments count and post age (no crawling)
- [ ] Ranking bonus for momentum (engagement relative to age), capped so job relevance still wins
- [ ] Send the 3 most-liked comments to the prompt as "already said — add something different"

### Phase 4c — Audience targeting (done in v0.7)

Done when: the ranking knows *who* wrote a post, not only *what* it says, and favours the places and
companies you are aiming for.

- [x] Read the author's headline from the feed (it's on screen next to the name) and validate the selector
- [x] `audiences` in the profile: terms per author type — recruiter ("Talent Acquisition", "Recruiter",
      "Recrutador"), hiring manager ("Head of Design", "Design Manager", "Engineering Manager"),
      bubble reference ("Senior Product Designer", "UX Lead"), peer (everything else)
- [x] `locations` (e.g. Vancouver, BC, Canada, Remote) and `target_companies` in the profile
- [x] Ranking bonus for author type, location and target company; `reason` explains it
      ("Hiring manager · Vancouver · UI/UX Design")
- [x] Comment prompt adapts to the author: recruiter → short, one relevant fact, no asking for a job;
      peer → add an idea or a technical question

- [x] Buttons only on cards with post text (skips "Who viewed your profile", job anniversaries)
- [ ] Calibrate: watch the badges for a week; add missing headline terms to `audiences` and fill `target_companies`
- [ ] Run the comment Prompt Lab (v3) on Ollama, especially the new recruiter case

Lesson: same pattern as `JobTarget` — editable lists in the profile, rules in Ruby, no AI.
Headline reading has no stable HTML hook, so it relies on the order of the lines; verified on the real feed.

### Phase 5 — History and metrics

Done when: you can see what was suggested, what you published and what got engagement.

- [ ] Add ActiveRecord + SQLite; suggestions and publications tables
- [ ] "I published this" action in the extension
- [ ] Re-capture likes/replies on your own comments later; compare angles (insight, question, experience)
- [ ] Simple dashboard: comments per week, replies received, job posts engaged with

### Phase 6 — Market insights and profile audit (proposed)

Done when: you can see which skills the job posts you see ask for most, and which of them your
profile doesn't show.

- [ ] Store every job post the extension sees (text, author type, location, date) — only what was on
      your screen, deduplicated, no crawling
- [ ] Read **job pages** you open (`linkedin.com/jobs/view/…`): full description, company, location,
      seniority. Much richer than a "we're hiring" feed post — the main source for skill demand
- [ ] Read **your own profile page** when you open it (headline, About) so the audit compares against
      what recruiters actually see, not only `profile.yml`
- [ ] `skills.yml`: a curated vocabulary of skills with synonyms ("usability testing" = "user testing",
      "testes de usabilidade"); count matches, not every word
- [ ] `MarketInsights` service: demand per skill (% of job posts that mention it), trend
      (last 14 days vs before), filtered by target role and location
- [ ] Profile audit: compare demand with your headline, highlights and keywords and sort each skill into
      **shown** (in headline), **hidden** (you have it — it's in your highlights — but the headline
      doesn't say it) or **gap** (not in your profile at all)
- [ ] Popup or dev page: "8 of 10 UX co-op posts mention *usability testing* — it's in your highlights,
      not in your headline"
- [ ] Optional: AI as a second pass to propose new vocabulary terms the list misses (you approve them)

Lesson: counting is code; the AI only suggests vocabulary. And: recruiters find people through
profile search, so the headline matters as much as comments and posts.

### Phase 7 — Insight-driven post ideas (proposed)

Done when: the Post Creator can suggest what to post next, based on what the market asks for and
what you can honestly show.

- [ ] `PostIdeas` service turns insights into briefs for the existing `GeneratePost`:
      - **hidden** skill + a matching highlight → proof post ("how I used X at work")
      - **gap** skill → learning-in-public post ("week 1 learning X: what surprised me") — never claims
        experience you don't have
      - trending topic in your bubble → opinion/discussion post with a closing question
- [ ] Popup: "Suggested next posts" list; picking one pre-fills the idea and topics
- [ ] Rotate skills so posts cover what the market wants over a few weeks, not the same one every time
- [ ] With Phase 5: measure which ideas got reactions and, above all, replies from recruiters and
      hiring managers; favour what works for you
- [ ] Optional: read your own stats page when you open it (profile views, search appearances) to see
      whether the posts move the needle with hiring people

Lesson: the AI never decides *what* is in demand — the data does. The AI only writes the post
from a brief built from facts.

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
| Data sources | Only LinkedIn pages you open (feed, job pages, your profile) | Richer data without crawling or automation; stays within LinkedIn's Terms |
| North star | Be seen by people who can hire you | Ranking, comments and post ideas are all judged by it |

## Risks

| Risk | Mitigation |
| --- | --- |
| LinkedIn changes its selectors | All in `selectors.js`; the extension warns when it can't find the text |
| Generic comments sound like a bot | Prompt bans empty praise; the user reviews before publishing |
| Ranking misses job posts worded differently | Terms are editable per target in `profile.yml`; calibrate in Phase 4 |
| AI costs go up | Ranking uses no AI; Ollama for development; provider switch by config |
| Prompt injection in post text | Post is wrapped in `<post>` and the prompt treats it as data only |
| Engagement rules are folk wisdom | Shown as a checklist, not a score; Phase 5 measures what works for you |
| Market insights from a small sample | Show counts ("8 of 10 posts"), not just percentages; filter by role and location |
| Post ideas push you to claim skills you don't have | Gap skills only become learning-in-public posts; facts still come only from highlights |

## Ideas beyond Phase 5

- Suggest 2–3 comment angles to choose from
- Schedule posts for peak reach times
- Use the AI as a second pass to classify ambiguous job posts the rules miss
