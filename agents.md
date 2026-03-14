# Agent Instructions

## Purpose

This is an exploration repository. The owner reads public codebases and writes analysis reports. There is no application code here — only reports and reference repos.

## Repo Layout

| Path        | Description                                                |
| ----------- | ---------------------------------------------------------- |
| `reports/`  | Markdown analysis files written by the owner               |
| `repos/`    | External repos as git submodules (read-only, not modified) |
| `README.md` | Human-facing overview                                      |
| `agents.md` | This file                                                  |
| `CLAUDE.md` | Symlink to this file                                       |

## Working in This Repo

Use the `just` commands defined in `justfile` for all submodule operations.

### Writing reports

- Reports go in `reports/`
- Name them after the subject repo, e.g. `reports/rig_report.md`
- Write in markdown

### Common commands

```bash
just add https://github.com/<owner>/<repo>        # add new submodule (name inferred)
just add https://github.com/<owner>/<repo> <name> # add with custom name
just fetch <name>                                  # download a single submodule
just fetch-all                                     # download all submodules
just update <name>                                 # update one to latest + commit
just update-all                                    # update all to latest + commit
just status                                        # show pinned commits
just list                                          # list all submodule paths
just clean <name>                                  # deinit a submodule (frees local disk, keeps registration)
```

> **Note:** After `just clean`, the repo folder will appear empty but should **not** be deleted. Git tracks submodules as gitlink objects (mode `160000`) — the empty directory is the placeholder for that pointer. Removing it stages a deletion of the submodule from the index.

### Claude permissions

Claude permissions are managed in two files:

- `.claude/settings.json` — checked into the repo; add allowed commands here (e.g. `just` commands)
- `.claude/settings.local.json` — local only, not committed; use for personal or machine-specific overrides

When updating permissions (e.g. allowlisting a new `just` command), edit `settings.json` so the change is shared with the repo.

## What NOT to Do

- Do not modify files inside `repos/` — they are external codebases
- Do not commit build artifacts or `.env` files
- Do not push to external submodule remotes
