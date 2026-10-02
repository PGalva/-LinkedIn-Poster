# ADR-0001: Plain-Ruby core with ports & adapters to isolate the AI provider

**Status:** Accepted — the HTTP framework choice (Sinatra) is superseded by [ADR-0002](0002-rails-as-the-http-layer.md)
**Date:** 2026-09-27
**Deciders:** Pedro Barbosa

## Context

LinkedIn Poster has two entry points (a Chrome extension that captures posts, and a form for
creating posts) and one expensive, volatile dependency: the AI provider. Requirements:

1. Swapping Claude for OpenAI or Ollama must be a configuration change, not a business-code change.
2. Business rules (prompt building, keywords, hashtags, ranking) must be testable without network access.
3. The API key must never live in the browser.
4. LinkedIn requires login to view posts, so a server that "opens the URL" cannot read the content.
   The extension captures the post from the page the user is already viewing.

## Decision

Hexagonal architecture (ports & adapters) around a plain-Ruby core:

```
Extension / Form  ──HTTP──►  Api (Sinatra, thin)
                               │ builds domain objects
                               ▼
                        Services (use cases)
                SuggestComment · GeneratePost · RankPosts
                  │              │                 │
         Prompts::*Builder   Text::* (keywords,   │ (no AI)
                  │           hashtags, parser)   │
                  ▼
        LLM port: #complete(Prompt) -> Response
                  │
   ┌──────────┬───┴─────┬──────────┐
 Anthropic   OpenAI   Ollama      Fake
                  │
          HttpTransport (single network entry point)
```

- `Domain::Prompt` is provider-neutral; each adapter translates it into its provider's format.
- Adapters translate provider errors into `LLM::Error` and its subclasses.
- `LLM.build` (the registry) picks the adapter from the `LLM_PROVIDER` environment variable.
- A contract test (`LLMContract`) runs against every adapter.
- The extension **suggests**; the user reviews and publishes (human in the loop).

## Options considered

### Option A: Plain-Ruby core + Sinatra (chosen)
| Dimension | Assessment |
|---|---|
| Complexity | Low |
| Cost | AI tokens only; Ollama makes development free |
| Scalability | Enough for one user; can move to Rails without rewriting the core |
| Team familiarity | High (Ruby/Rails background) |

**Pros:** core tests run in milliseconds; little "magic" to learn; easy migration later.
**Cons:** no ORM or migrations out of the box once history needs to be stored.

### Option B: Rails API from day one
| Dimension | Assessment |
|---|---|
| Complexity | Medium |
| Cost | Same |
| Scalability | High, multi-user ready |
| Team familiarity | High |

**Pros:** ActiveRecord, background jobs and authentication ready when this becomes a product.
**Cons:** lots of generated code before the idea is validated; temptation to put rules in models/controllers.

### Option C: Call official SDKs (anthropic gem, ruby-openai) directly from services
**Pros:** less code now. **Cons:** services become coupled to one provider — exactly what
requirement 1 forbids. SDKs can still be used *inside* an adapter if worthwhile.

## Trade-off analysis

We pay roughly 150 lines of adapters and transport code to get provider switching by configuration,
offline tests, and a single error format. For a project whose main risk is "the AI changes or gets
more expensive", that is worth it. Rails remains a natural next step: `lib/` plugs into `app/services`
unchanged.

## Consequences

- Easier: swapping or adding an AI provider, testing prompts, running offline with `LLM_PROVIDER=fake`.
- Harder: provider-specific features (tool use, streaming) require carefully widening the port —
  only when there is a real need.
- Revisit: persistence (comment history, profile in a database) and multi-user support.
- LinkedIn's DOM selectors break often; they are isolated in `extension/selectors.js`.

## Action items

1. [x] Core, adapters and contract tests
2. [x] Docker environment and offline mode
3. [ ] Phase 1: `/comments/suggest` end to end with Claude
4. [ ] Phase 2: extension loaded in Chrome, selectors validated
5. [ ] Phase 3: Post Creator form
6. [ ] Phase 4: feed ranking
7. [ ] Phase 5: persistence and metrics
