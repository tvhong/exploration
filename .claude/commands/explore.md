---
description: Explore a repo in repos/ and write a structured analysis report to reports/. Triggers when the user wants to understand a repository they just added or asks "what is X about", "explore X", "analyze X", or "write a report on X". Use this skill whenever exploration of a submodule is requested, even informally.
---

# Repo Explorer

You are writing a structured analysis report for a repository that was recently added as a submodule.

## Input

The user will name a repo (e.g. "gstack", "rig", "llm"). The repo lives at `repos/<name>/`.

If the user didn't specify a name, ask which repo in `repos/` they want to explore.

## Research process

Read up to ~25 files. Prioritize in this order:

1. `README.md`, `README.rst`, or top-level docs
2. `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, or equivalent (to understand language, deps, entry points)
3. Top-level source directory — scan structure with Glob, then read 3-5 key files
4. Any `ARCHITECTURE.md`, `DESIGN.md`, `docs/` folder, or inline diagrams
5. Main entry point file(s) — `main.py`, `src/index.ts`, `cmd/`, etc.
6. A few representative feature files that illustrate how the system actually works

Use Glob and Grep liberally to orient yourself before reading files. Don't read test files, lock files, or generated output unless something specific is unclear.

## Report structure

Write the report to `reports/<name>_<YYYY-MM-DD>.md` where the date is today's date.

Use this exact structure:

```
# <Repo Name>

> <One-sentence summary of what it does>

## What is it?

What problem does this solve, and for whom? What was the motivation for building it?

## Ecosystem fit & innovations

Where does this sit in the broader world of tools, frameworks, or workflows? What are the interesting or novel design choices? What makes this different from alternatives?

## Main components

A breakdown of the major pieces of the system. Use a table or bullet list. For each component: name, what it does, where it lives in the repo.

## How it works & data flow

How do the components interact? What happens step by step when the system is used? Trace the path of data from input to output. Include a simple ASCII diagram if it helps.

---
*Explored on <date> · ~<N> files read*
```

## After writing

Tell the user the report has been saved and offer to answer follow-up questions about any part of the repo. You still have the context from your research — use it.
