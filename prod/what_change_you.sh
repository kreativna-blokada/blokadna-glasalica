#!/bin/bash

DEFAULT_SHA="4daa920641b46afc5e179175aa40991ec8097950"
DEFAULT_EXT="gd"
DEFAULT_REPO_PATH="/Users/zeljkov/Desktop/workspace/Blokadna Igrica/!project/blokadna-glasalica/"

SHA=${1:-$DEFAULT_SHA}
EXT=${2:-$DEFAULT_EXT}
REPO_PATH=${3:-$DEFAULT_REPO_PATH}

REPO_PATH="${REPO_PATH/#\~/$HOME}"

# Verify the REPO_PATH exists
cd "$REPO_PATH" || { echo "Error: Path not found ($REPO_PATH)"; exit 1; }

# Verify the SHA exists
if ! git rev-parse --verify "$SHA" >/dev/null 2>&1; then
    echo "Error: SHA $SHA not found."
    exit 1
fi

echo "Listing all .$EXT files changed from $SHA up to HEAD..."
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

# Use 'git diff' to see the range of changes
# --name-only: gives just the filenames
git diff --name-only "$SHA" HEAD | grep "\.${EXT}$" || echo "No .$EXT files have changed in this range."
