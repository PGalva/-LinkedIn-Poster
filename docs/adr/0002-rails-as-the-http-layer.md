# ADR-0002: Rails (API only) as the HTTP layer

**Status:** Accepted — supersedes the Sinatra choice in ADR-0001
**Date:** 2026-10-01
**Deciders:** Pedro Barbosa

## Context

ADR-0001 chose Sinatra for the HTTP layer and said migrating to Rails later would only touch the
HTTP code. Phase 5 needs persistence (comment history, metrics), and the author already works with
Rails day to day. Moving now, while the HTTP layer is ~70 lines, is cheaper than later.

## Decision

Replace `app/api.rb` (Sinatra) with a Rails 8 API-only app:

- Only `action_controller` is loaded. ActiveRecord is added in Phase 5, not before.
- One thin controller per resource: `HealthController`, `CommentsController`, `PostsController`.
- `ApplicationController` maps core errors to HTTP (`ValidationError` → 422, rate limit → 429,
  other `LLM::Error` → 502).
- `config/initializers/linkedin_poster.rb` is the composition root: it requires the core and builds
  the LLM adapter and profile once.
- The core in `lib/linkedin_poster` is **not** autoloaded by Zeitwerk. It stays plain Ruby, and its
  folder names (`llm/`) would clash with Zeitwerk's naming (`LLM` vs `Llm`).

## Consequences

- Easier: ActiveRecord, migrations and background jobs are one `require` away for Phase 5; familiar
  conventions for anyone who knows Rails.
- Harder: a heavier dependency tree and a slower Docker build.
- Unchanged: every service, adapter and core test. Only the HTTP layer moved — which is the
  point of the architecture in ADR-0001.
- Core changes in `lib/` need a server restart in development; controller changes reload automatically.
