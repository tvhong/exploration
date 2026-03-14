# Add a new submodule under repos/
# Usage: just add https://github.com/owner/repo [name]
add repo name=`basename $repo .git`:
    git submodule add {{repo}} repos/{{name}}
    git add .gitmodules repos/{{name}}
    git commit -m "Add {{name}} as submodule"

# Fetch (init + download) a single submodule without fetching the rest
fetch name:
    git submodule update --init repos/{{name}}

# Fetch all submodules
fetch-all:
    git submodule update --init --recursive

# Update a single submodule to the latest commit on its tracked branch
update name:
    git submodule update --remote repos/{{name}}
    git add repos/{{name}}
    git commit -m "Update {{name}} to latest"

# Update all submodules to their latest commits
update-all:
    git submodule update --remote
    git add repos/
    git commit -m "Update all submodules to latest"

# Show status of all submodules (pinned commit SHA + dirty state)
status:
    git submodule status

# List all registered submodule paths
list:
    git config --file .gitmodules --get-regexp path | awk '{ print $2 }'
