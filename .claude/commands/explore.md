---
description: Explore a repo in repos/ and write a structured analysis report to reports/. Triggers when the user wants to understand a repository they just added or asks "what is X about", "explore X", "analyze X", or "write a report on X". Use this skill whenever exploration of a submodule is requested, even informally.
allowed-tools: Read, Glob, Grep, Write, Bash(just add*), Bash(just fetch*)
---

# Repo Explorer

You are writing a structured analysis report for a repository that was recently added as a submodule.

## Input

The user will name a repo (e.g. "gstack", "rig", "llm"). The repo lives at `repos/<name>/`.

If the user didn't specify a name, ask which repo in `repos/` they want to explore.

Before starting research, check whether `repos/<name>/` exists and has content. If it's empty or missing, run `just add <url>` (if the user provided a URL) or `just fetch <name>` (if the submodule is already registered) to populate it first.

## Research process

Read up to ~25 files. Prioritize in this order:

1. `README.md`, `README.rst`, or top-level docs
2. `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, or equivalent (to understand language, deps, entry points)
3. Top-level source directory — scan structure with Glob, then read 3-5 key files
4. Any `ARCHITECTURE.md`, `DESIGN.md`, `docs/` folder, or inline diagrams
5. Main entry point file(s) — `main.py`, `src/index.ts`, `cmd/`, etc.
6. A few representative feature files that illustrate how the system actually works
7. Git history and version info — check `git log --oneline -20` in the repo directory, look at version numbers in manifests, and note creation date / recent activity to inform the maturity assessment

Use Glob and Grep liberally to orient yourself before reading files. Don't read test files, lock files, or generated output unless something specific is unclear.

## Report structure

Write the report to `reports/<name>_<YYYY-MM-DD>.md` where the date is today's date.

The report has two parts: a **5C overview** for quick orientation, followed by **detailed sections** for readers who want to go deeper. Think of the 5Cs like skimming a paper — you get the essential picture fast — and the detailed sections like actually reading it.

Use this exact structure:

```
# <Repo Name>

> <One-sentence summary of what it does>

## 5C Overview

### Category

What type of artifact is this — library, CLI tool, web app, framework, plugin, platform, etc.? What language/ecosystem? Who is the target user?

### Context

What problem space does this live in? What is the current state of this domain — what tools, approaches, or standards already exist? This sets the stage for understanding why the repo matters.

### Contribution

What does this repo specifically add to the field? What gap does it fill, what does it do differently or better than alternatives? This is the "so what" — the reason someone would choose this over existing options.

### Correctness

How mature and reliable does this appear? Look at: version number (pre-1.0 vs stable), test coverage, CI setup, error handling patterns, age of the project, commit activity trajectory, and adoption signals (stars, forks, dependents if available from the README or badges). Is this production-ready, experimental, or somewhere in between?

### Clarity

How easy is it to understand and use? Assess documentation quality (README, guides, API docs), code readability (naming, structure, comments where needed), and onboarding experience (quickstart, examples, clear entry points).

## Main components

A breakdown of the major pieces of the system. Use a table or bullet list. For each component: name, what it does, where it lives in the repo.

## How it works & data flow

How do the components interact? What happens step by step when the system is used? Trace the path of data from input to output. Include a simple ASCII diagram if it helps.

---
*Explored on <date> · ~<N> files read*
```

## After writing

Tell the user the report has been saved and offer to answer follow-up questions about any part of the repo. You still have the context from your research — use it.
