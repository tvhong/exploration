# FastCode — Analysis Report

> Generated: 2026-03-07
> Source: HKUDS/FastCode repo + paper [arXiv:2603.01012](https://arxiv.org/html/2603.01012v1)

---

## 1. What Is FastCode?

FastCode is a **code-understanding / Q&A system** — not an agentic coding tool in the SWE-bench sense. It takes a codebase and a natural-language question and returns an answer with source references. It does **not** write or edit code; it is designed purely for **code comprehension and navigation** tasks.

It is built by the Data Intelligence Lab at HKU (HKUDS), the same group behind GraphRAG-based recommender systems.

---

## 2. How Is It Different from Other Agentic Coding Systems?

### The Core Claim: "Scouting-First"

Most agentic coding systems (SWE-agent, OpenHands, Claude Code, Cursor) work by **iteratively opening files** as they search. A typical loop looks like:

```
Question → open file A → read it → open file B → read it → ... → answer
```

Each file load costs tokens. Deep, sprawling repos are expensive because the agent reads a lot of irrelevant content on the way to the answer.

FastCode flips this with a **scouting-first, two-phase pipeline**:

```
Question → build semantic map → navigate graph structure → load only targets → answer
```

1. **Scout phase**: Use lightweight metadata (function signatures, class names, type hints, AST-derived graphs) to identify *candidate* elements without loading full bodies.
2. **Load phase**: Read full source only for the narrowed-down set.

This is sometimes called **"code skimming"** — reading chapter titles before reading the book.

### Not a General Agent

Unlike Cursor Agent or Claude Code, FastCode does **not**:
- Execute code
- Run tests
- Write patches
- Manage shell commands

It is **read-only** by design. The `AgentTools` class (`fastcode/agent_tools.py`) offers only: `list_directory`, `search_codebase`, `get_file_info`, `get_file_structure_summary`, `read_file_content` — all gated behind a repo-root security boundary.

### Comparison Table

| Feature | Claude Code / Cursor | SWE-agent / OpenHands | FastCode |
|---|---|---|---|
| Writes/edits code | ✅ | ✅ | ❌ |
| Executes code | ✅ | ✅ | ❌ |
| Code Q&A / understanding | ✅ (incidental) | ✅ (incidental) | ✅ (primary) |
| Token-efficient navigation | ❌ | ❌ | ✅ |
| Pre-built index (FAISS+BM25+graphs) | ❌ | ❌ | ✅ |
| Works offline / local models | ❌ | ❌ | ✅ |

---

## 3. Claims: Speed and Cost

### The Numbers (from paper arXiv:2603.01012)

| Benchmark | FastCode | Cursor | Claude Code |
|---|---|---|---|
| **SWE-QA accuracy** | 43.28 | 43.17 | 42.08 |
| **SWE-QA cost/query** | $0.032 | $0.071 (55% more) | $0.057 (44% more) |
| **LOC-BENCH Acc@1** | **86.13%** | — | — |
| **Previous SOTA (LocAgent)** | 77.74% | — | — |
| **GitTaskBench pass rate** | **57.41%** (Claude 3.7) | — | 48.15% |
| **LongCodeQA @ 1M tokens cost** | ~$0.073 | — | ~$2.60 (direct) |

README headline claims ("3x faster, 4x faster than Claude Code") appear to refer to **wall-clock latency** inferred from token reduction, not directly measured end-to-end elapsed time. The paper itself primarily measures **token count and dollar cost**, not seconds.

### How Is Speed Measured?

From the paper and README:
- **Cost** = tokens consumed × API price per token (third-party API pricing)
- **Speed** = correlated with cost; fewer tokens → fewer API round-trips → faster
- The "3x / 4x faster" headline is a derived metric, not a direct stopwatch measurement

The paper does not present wall-clock timing tables. The speed claims are reasonable inferences from token efficiency but should not be taken as direct latency benchmarks.

---

## 4. Evaluating Validity of Claims

### What Holds Up

| Claim | Assessment |
|---|---|
| Significantly cheaper token usage | **Credible**. The mechanism (scouting before loading) is sound. Cost tables in the paper are detailed. |
| LOC-BENCH improvement over prior SOTA | **Credible but narrow**. +8.4pp over LocAgent on file localization — a task FastCode is specifically optimized for. |
| GitTaskBench improvement over OpenHands | **Credible with caveats** — same backbone (Claude 3.7) so apples-to-apples. |
| "3x/4x faster than Cursor/Claude Code" | **Misleading framing**. It means fewer tokens, not necessarily faster wall-clock time. |
| "Highest accuracy score" | **Weak claim on SWE-QA** — FastCode's 43.28 vs. Cursor's 43.17 is essentially a tie (0.25% diff), not a clear win. |

### Structural Concerns

1. **Task mismatch**: Cursor and Claude Code are general coding agents. Comparing them on *read-only code Q&A* is unfair — they are not optimized for this task. FastCode wins on its home turf.

2. **Ablation is small**: The paper's ablation uses only "a three-repository subset," limiting generalizability of the component analysis.

3. **Language scope**: Benchmarks are Python-heavy. FastCode supports 8 languages but the evaluation is narrow.

4. **Indexing cost not counted**: FastCode requires upfront indexing (FAISS + BM25 + 3 graphs). This one-time cost is not included in per-query cost comparisons. For one-shot queries on a new repo, FastCode may actually be *more* expensive end-to-end.

5. **API pricing volatility**: Cost comparisons are locked to a snapshot of API prices. Results will shift as models change.

6. **No statistical significance reported**: Benchmark differences are reported as point estimates without confidence intervals.

---

## 5. Architecture

### Entry Points

| Interface | File |
|---|---|
| CLI | `main.py` |
| Web UI | `web_app.py` |
| REST API | `api.py` |
| MCP Server (Cursor/Claude Code) | `mcp_server.py` |
| Feishu/Nanobot Docker | `docker-compose.yml` + `run_nanobot.sh` |

### Core Pipeline (`fastcode/`)

```
User Query
    │
    ▼
query_processor.py          ← Query rewriting, complexity scoring, pseudocode hints
    │
    ▼
iterative_agent.py          ← Confidence-based multi-round retrieval controller
    │         │
    │         ├─→ agent_tools.py       ← Safe read-only file tools (list, search, read, skim)
    │         └─→ retriever.py         ← Two-stage search: vector + BM25 re-rank
    │                    │
    │                    ├─→ vector_store.py    ← FAISS index
    │                    └─→ graph_builder.py   ← NetworkX graphs (call/dep/inheritance)
    │
    ▼
answer_generator.py         ← Final LLM call to synthesize answer from retrieved context
```

### Indexing Pipeline (one-time, offline)

```
loader.py          ← Scan files, read content
    │
    ▼
parser.py / tree_sitter_parser.py  ← AST parsing for 8+ languages
    │
    ▼
indexer.py         ← CodeElement dataclass at 4 levels: file, class, function, documentation
    │
    ├─→ embedder.py        ← Embedding generation (text-embedding model)
    ├─→ vector_store.py    ← FAISS persistence (.faiss files)
    ├─→ cache.py           ← BM25 index (.pkl files)
    └─→ graph_builder.py   ← 3 NetworkX graphs saved as _graphs.pkl
```

### Key Components Explained

**`CodeElement` (indexer.py:19)**
The fundamental data unit. Represents a file, class, function, or docstring with: id, type, name, file_path, line range, code, signature, docstring, summary, and embedding.

**`IterativeAgent` (iterative_agent.py)**
The orchestration brain. Runs 2–6 rounds (adaptive based on query complexity + repo size). Each round:
- Calls the LLM to assess confidence (0–100) given current evidence
- Decides which tools to call next (list_dir, search, read_file, get_structure)
- Checks if confidence gain per new lines loaded exceeds an ROI threshold
- Stops when confidence ≥ threshold OR line budget exhausted

**`AgentTools` (agent_tools.py)**
Sandboxed file system access. All paths are validated against repo_root. Provides "code skimming" via `get_file_structure_summary` which reads only the first 100 lines to extract class/function signatures.

**`CodeGraphBuilder` (graph_builder.py)**
Builds three NetworkX directed graphs:
- **Call Graph**: function → called functions
- **Dependency Graph**: file → imported files (via import_extractor.py)
- **Inheritance Graph**: class → parent classes

Used by the retriever to traverse relationships ("follow code connections up to 2 steps away").

**`HybridRetriever` (retriever.py)**
Parallel search combining FAISS and BM25 (not sequential re-ranking):
1. FAISS semantic search → top 20 candidates
2. BM25 keyword search → top 10 candidates (independently, in parallel)
3. Scores combined with weights: FAISS 60%, BM25 30%, graph 10%
4. Re-rank final merged list

Note: graph expansion is **commented out** in the standard retrieval path. It only activates inside the iterative agency loop.

**`query_processor.py`**
Augments the raw user query with:
- Query rewriting for embedding quality
- Complexity scoring (0–100)
- Pseudocode/hint generation to guide retrieval

**`repo_selector.py`**
For multi-repo queries: uses LLM to select which repos are relevant before searching.

### Configuration

`config/config.yaml` controls all thresholds:
- `agent.iterative.max_iterations` (default 4)
- `agent.iterative.confidence_threshold` (default 95)
- `agent.iterative.max_total_lines` (default 12,000)
- `indexing.levels`: [file, class, function, documentation]
- `graph.build_call_graph`, `build_dependency_graph`, `build_inheritance_graph`

---

## 6. Summary Verdict

FastCode is a **well-engineered, focused tool** for code Q&A with a genuinely novel retrieval approach. Its cost savings on token consumption are real and substantial. However:

- The marketing framing ("3x/4x faster", "highest accuracy") overstates some results
- It is not a fair comparison to general agents like Claude Code or Cursor — it solves a narrower, read-only problem
- The indexing overhead is not counted in the cost comparisons
- The accuracy lead over Cursor on SWE-QA is statistically negligible

**Best use case**: Navigating and understanding large, stable codebases where upfront indexing cost is amortized across many queries. Poor fit for one-off exploration of a new repo or any task requiring code generation/execution.

---

## 7. Key Technology Concepts

### FAISS (Vector Index)

FAISS (Facebook AI Similarity Search) is an in-process library for fast nearest-neighbor search over high-dimensional vectors. There is no separate vector DB server — it persists as plain `.faiss` files on disk.

The naive approach to vector search is brute-force: compare the query vector against every stored vector (O(N)). FAISS avoids this with approximate algorithms. FastCode uses **HNSW** (Hierarchical Navigable Small World graphs) — a graph-based index where each vector is connected to its nearest neighbors, allowing search to "hop" toward the answer rather than scanning everything. Fast, with a small accuracy trade-off.

### Embedding Model

FastCode uses `sentence-transformers` (default: `all-MiniLM-L6-v2`) running **fully locally** via PyTorch. No API calls, no cost. It maps text → a fixed-size vector (e.g. 384 numbers) such that semantically similar texts land close together in that space. FastCode runs `SentenceTransformer.encode()` and stores the output directly — no additional processing.

At query time, the query goes through the same embedding model to get a query vector, then FAISS finds the stored vectors closest to it.

### BM25

BM25 is a classical keyword relevance algorithm (same family as Elasticsearch's scoring). It works on **raw text tokens**, not embeddings — completely separate pipeline.

For each code element, FastCode concatenates: `name + type + language + path + docstring + signature + first 1000 chars of code`, lowercases and whitespace-tokenizes it. At query time, BM25 scores every document based on term frequency (how often the query words appear) and inverse document frequency (rare words get higher weight), with length normalization.

FAISS and BM25 catch different things:
- **FAISS**: finds semantically similar code — e.g. "user login" surfaces `verify_credentials()` even without word overlap
- **BM25**: finds exact keyword matches — reliable for specific function names or identifiers

### How They Combine (Corrected Pipeline)

FAISS and BM25 run **in parallel** (not sequentially). Both independently retrieve candidates; their scores are then weighted and merged (60/30/10 for FAISS/BM25/graph). The graph expansion only runs inside the iterative agency loop, not in the standard retrieval path:

```
Query
  │
  ├─→ embed → FAISS search        → top 20 candidates
  ├─→ tokenize → BM25 search      → top 10 candidates
  │
  ├─→ combine scores (60% / 30%) → merged candidate pool
  │
  [agency mode only]:
  └─→ graph expand (2 hops) → add structural neighbors
  │
  └─→ re-rank → top N → LLM answer generation
```

### NetworkX Graphs (What They're Used For)

The three graphs (call, dependency, inheritance) give the retriever **structural awareness** that pure text search can't provide.

Use case: you search "authentication" and FAISS finds `verify_token()`. But to fully answer "how does auth work?", you also need `check_session()` (which calls `verify_token()`), the `User` class (which `verify_token()` checks), and `auth_middleware.py` (which imports both) — none of which necessarily contain the word "authentication."

Graph expansion walks those relationships: start from a matched element, follow edges 1–2 hops outward, and pull in structural neighbors. This activates only during the confidence-based iterative loop, after the initial FAISS+BM25 retrieval round.

---

## Sources

- [arXiv paper: FastCode: Fast and Cost-Efficient Code Understanding and Reasoning](https://arxiv.org/html/2603.01012v1)
- [GitHub: HKUDS/FastCode](https://github.com/HKUDS/FastCode)
- [GitTaskBench paper](https://arxiv.org/abs/2508.18993)
