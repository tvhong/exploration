# exploration

A personal repo for exploring and documenting public codebases.

## Structure

```
exploration/
├── reports/      # Analysis and notes on explored repos
├── repos/        # Public repos as git submodules (read-only reference)
├── agents.md     # Instructions for AI agents working in this repo
└── CLAUDE.md     # Symlink → agents.md
```

## Reports

Write-ups live in `reports/`. Each report is a standalone markdown file, typically named after the repo it covers (e.g. `fastcode_report.md`).

## Reference Repos

External repos are tracked as git submodules under `repos/`. They are pinned to a specific commit and are not modified.

### Add a new repo

```bash
git submodule add https://github.com/<owner>/<repo> repos/<repo>
git add .gitmodules repos/<repo>
git commit -m "Add <repo> as submodule"
```

### Clone this repo (including submodules)

```bash
git clone --recurse-submodules <url>
```

### Pull only one submodule

```bash
git submodule update --init repos/<repo>
```

### Update a submodule to latest

```bash
git submodule update --remote repos/<repo>
git add repos/<repo>
git commit -m "Update <repo> to latest"
```
