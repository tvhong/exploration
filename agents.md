# Agent Instructions

## Purpose

This is an exploration repository. The owner reads public codebases and writes analysis reports. There is no application code here — only reports and reference repos.

## Repo Layout

| Path | Description |
|------|-------------|
| `reports/` | Markdown analysis files written by the owner |
| `repos/` | External repos as git submodules (read-only, not modified) |
| `README.md` | Human-facing overview |
| `agents.md` | This file |
| `CLAUDE.md` | Symlink to this file |

## Working in This Repo

### Writing reports

- Reports go in `reports/`
- Name them after the subject repo, e.g. `reports/rig_report.md`
- Write in markdown

### Adding a submodule

```bash
git submodule add https://github.com/<owner>/<repo> repos/<repo>
git add .gitmodules repos/<repo>
git commit -m "Add <repo> as submodule"
```

### Updating a submodule to latest

```bash
git submodule update --remote repos/<repo>
git add repos/<repo>
git commit -m "Update <repo> to latest"
```

### Fetching a single submodule (without fetching all)

```bash
git submodule update --init repos/<repo>
```

## What NOT to Do

- Do not modify files inside `repos/` — they are external codebases
- Do not commit build artifacts or `.env` files
- Do not push to external submodule remotes
