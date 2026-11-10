#!/usr/bin/env bash
# Apply the a35x source patches to an OrangeFox fox_12.1 checkout.
# Run from the root of the source tree:
#   bash device/samsung/a35x/patches/apply.sh
# Each folder name is the project path with "/" written as "_".
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
for dir in "$here"/*/; do
    project=$(basename "$dir" | tr _ /)
    [ -d "$project/.git" ] || [ -f "$project/.git" ] || { echo "Missing project: $project" >&2; exit 1; }
    echo "Applying patches to $project"
    git -C "$project" am --3way "$dir"*.patch
done
echo "All a35x patches applied."
