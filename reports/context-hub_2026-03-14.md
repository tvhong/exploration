# Context Hub

> A curated, versioned documentation registry and CLI that gives coding agents accurate API docs and reusable skills, fighting hallucination at the source.

## What is it?

Coding agents hallucinate API signatures and forget hard-won knowledge between sessions. Context Hub (published as `@aisuite/chub`) addresses this by providing:

1. **Curated docs** — human-reviewed, LLM-optimized markdown files for popular libraries (OpenAI, Stripe, Anthropic, hundreds more), versioned and language-specific.
2. **Skills** — reusable agent instruction files (SKILL.md) that teach agents to perform multi-step tasks.
3. **A local annotation layer** — agents can attach notes to docs that persist across sessions, so they can learn from past fixes without re-discovering the same workarounds.

The project is by Andrew Ng's team (AI Fund / DeepLearning.AI), positioned as tooling for the AI developer ecosystem. The intended user is not a human, but the coding agent itself — prompted to call `chub` before writing code against a new API.

## Ecosystem fit & innovations

Context Hub sits at the intersection of package managers, documentation sites, and agent memory.

**Compared to alternatives:**
- Unlike `llms.txt` (a convention to add LLM-friendly docs to an existing site), Context Hub is a centralised, community-curated registry. Content is in the repo, inspectable, and PR-contributable.
- Unlike RAG over raw web search, docs are hand-curated for LLM consumption — no noise, no stale StackOverflow threads.
- Unlike agent memory systems (MemGPT, mem0), this is public and shared: feedback from one agent improves docs for everyone.

**Novel design choices:**
- **Two content types are distinct**: DOC.md (API docs, language+version specific) vs SKILL.md (procedure/workflow, flat). The registry schema and fetch path diverge cleanly for each.
- **BM25 search index ships with the content** — full-text search works offline with no external service.
- **Bundled content in the npm package** — the first `chub get` works without any network call; the bundled dist/ directory is baked in at publish time via the `prepublish` script.
- **MCP server dual-mode** — the same content is accessible via both CLI (for shell-based agents) and MCP (for Claude Code, Cursor). The MCP server redirects all console.log to stderr to protect the stdio JSON-RPC channel.
- **Agent feedback loop** — up/down votes flow back to doc authors via PostHog analytics; authors can then update the community content.

## Main components

| Component | What it does | Location |
|-----------|-------------|----------|
| **CLI (`chub`)** | Entry point; registers all commands via Commander | `cli/src/index.js` |
| **`get` command** | Fetches a doc or skill by ID; handles language/version resolution, annotations, incremental fetch | `cli/src/commands/get.js` |
| **`search` command** | Full-text BM25 search or keyword fallback over the registry | `cli/src/commands/search.js` |
| **`build` command** | Scans `content/` to produce `registry.json` + BM25 search index + copied file tree | `cli/src/commands/build.js` |
| **`annotate` command** | Read/write/clear local agent notes that appear on future fetches | `cli/src/commands/annotate.js` |
| **`feedback` command** | Send up/down ratings with labels to doc authors | `cli/src/commands/feedback.js` |
| **`cache` / `update` commands** | Manage the local `~/.chub/` cache of remote registries | `cli/src/commands/cache.js`, `update.js` |
| **Registry library** | Merges multi-source registries, resolves IDs, handles language/version lookup, deduplication | `cli/src/lib/registry.js` |
| **Cache library** | Fetch-with-cache logic: local → bundled dist → CDN; handles full bundle (tar.gz) downloads | `cli/src/lib/cache.js` |
| **BM25 library** | Pure-JS BM25 indexer and search; supports field-weighted scoring across name/description/tags | `cli/src/lib/bm25.js` |
| **MCP server (`chub-mcp`)** | Exposes search, get, list, annotate, feedback as MCP tools + a registry resource | `cli/src/mcp/server.js`, `tools.js` |
| **Content tree** | Curated doc and skill files in markdown with YAML frontmatter | `content/<author>/docs/<name>/<lang>/DOC.md` |

## How it works & data flow

### Content structure

```
content/
  openai/
    docs/
      chat/
        python/
          DOC.md        ← YAML frontmatter + LLM-optimised markdown
          references/
            streaming.md
        javascript/
          DOC.md
  pw-community/
    skills/
      login-flows/
        SKILL.md
```

Each `DOC.md` has frontmatter declaring `name`, `description`, and `metadata` (languages, versions, tags, source). `SKILL.md` is flat — no language/version dimension.

### Build pipeline (publish time)

```
content/ tree
    │
    ▼
chub build           ← scans author dirs, parses frontmatter
    │
    ├─▶ registry.json     (doc + skill index with paths)
    ├─▶ search-index.json (pre-computed BM25 IDF weights)
    └─▶ dist/             (copied content files)
         └─ (bundled inside npm package at publish)
```

### Runtime fetch flow

```
Agent: chub get openai/chat --lang py
           │
           ▼
    ensureRegistry()
    ┌──────────────────────────────────┐
    │  1. Local ~/.chub/ cache fresh?  │
    │  2. Bundled dist/ in npm pkg?    │
    │  3. Fetch from CDN (aichub.org)  │
    └──────────────────────────────────┘
           │
           ▼
    registry.js: resolve ID → language → version → file path
           │
           ▼
    cache.js: fetchDoc()
    ┌─────────────────────────────────────┐
    │  1. Local source path (if config'd) │
    │  2. ~/.chub/sources/<name>/data/    │
    │  3. dist/ bundled in package        │
    │  4. GET <cdn>/<path> + cache write  │
    └─────────────────────────────────────┘
           │
           ▼
    stdout: markdown content
    + appended annotation (if any)
    + list of additional reference files
```

### Agent self-improvement loop

```
Session N                          Session N+1
──────────────────                 ──────────────────────
chub get stripe/api   →  code fails   chub get stripe/api
                      →  agent notes  → doc + annotation shown
chub annotate stripe/api "Webhook       automatically
  needs raw body"
                      →  chub feedback stripe/api down
                         (sent to maintainers via PostHog)
                                   Maintainers update DOC.md
                                   → chub update → everyone benefits
```

## Project status & adoption

- **First commit**: December 19, 2025. Public announcement by Andrew Ng: March 9, 2026.
- **Version**: v0.1.2 — pre-1.0, functional but early. Skills are listed as "on the roadmap."
- **Stars**: ~5.9k within days of launch, entirely from the Andrew Ng announcement effect.
- **Content**: ~68 APIs at launch, community contributions via PRs.
- No dedicated browse website — the canonical way to explore available docs is `chub search` or browsing `content/` on GitHub. The raw registry is also publicly accessible at `https://cdn.aichub.org/v1/registry.json`.

## Limitations worth noting

**Content staleness is the core risk.** When an API ships a breaking change, nothing automatically updates the docs. A human must submit a PR. The feedback (up/down) system signals to maintainers what's outdated, but acting on it is manual. An agent consuming a confidently-presented but quietly-stale doc may be worse off than one that searches the web.

**Annotations are local-only.** Annotations live at `~/.chub/annotations/<entry-id>.json` on the user's machine, persist indefinitely, and are never shared. They help a single agent learn across sessions but provide no benefit to anyone else.

**Feedback goes to a private backend.** `chub feedback` POSTs to `api.aichub.org/v1/feedback` — not GitHub Issues. There's no public dashboard; the data is only visible to the Context Hub team.

**Intended consumption is via MCP.** Install `chub-mcp` once, point Claude Code or Cursor at it, and the agent can call `chub_search` / `chub_get` as tools. The CLI is available for manual use or shell-based agents.

---
*Explored on 2026-03-14 · ~15 files read*
