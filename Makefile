# Usage:
#   make add REPO=https://github.com/owner/repo          # add new submodule
#   make add REPO=https://github.com/owner/repo NAME=foo  # add with custom name
#   make fetch NAME=rig                                   # fetch one submodule
#   make fetch-all                                        # fetch all submodules
#   make update NAME=rig                                  # update one to latest
#   make update-all                                       # update all to latest
#   make status                                           # show submodule status
#   make list                                             # list submodule paths

.PHONY: add fetch fetch-all update update-all status list help

# Derive NAME from the last segment of REPO url if not set
NAME ?= $(notdir $(REPO))

## Add a new submodule
## Usage: make add REPO=https://github.com/owner/repo [NAME=custom-name]
add:
ifndef REPO
	$(error REPO is required. Usage: make add REPO=https://github.com/owner/repo)
endif
	git submodule add $(REPO) repos/$(NAME)
	git add .gitmodules repos/$(NAME)
	git commit -m "Add $(NAME) as submodule"

## Fetch (init + download) a single submodule without fetching the rest
## Usage: make fetch NAME=rig
fetch:
ifndef NAME
	$(error NAME is required. Usage: make fetch NAME=<repo-name>)
endif
	git submodule update --init repos/$(NAME)

## Fetch all submodules
fetch-all:
	git submodule update --init --recursive

## Update a single submodule to the latest commit on its tracked branch
## Usage: make update NAME=rig
update:
ifndef NAME
	$(error NAME is required. Usage: make update NAME=<repo-name>)
endif
	git submodule update --remote repos/$(NAME)
	git add repos/$(NAME)
	git commit -m "Update $(NAME) to latest"

## Update all submodules to their latest commits
update-all:
	git submodule update --remote
	git add repos/
	git commit -m "Update all submodules to latest"

## Show status of all submodules (commit SHA + dirty state)
status:
	git submodule status

## List all registered submodule paths
list:
	git config --file .gitmodules --get-regexp path | awk '{ print $$2 }'

help:
	@echo "Targets:"
	@echo "  add NAME=<name> REPO=<url>  Add a new submodule under repos/"
	@echo "  fetch NAME=<name>           Fetch a single submodule"
	@echo "  fetch-all                   Fetch all submodules"
	@echo "  update NAME=<name>          Update one submodule to latest"
	@echo "  update-all                  Update all submodules to latest"
	@echo "  status                      Show submodule status"
	@echo "  list                        List all submodule paths"
