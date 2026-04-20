#!/usr/bin/env bash
set -euo pipefail

PUBLISH_DIR="public"

rm -rf "$PUBLISH_DIR"
mkdir -p "$PUBLISH_DIR"

cp README.md "$PUBLISH_DIR/index.md"

for skill_dir in skills/*/; do
    skill_name=$(basename "$skill_dir")
    if [ -f "$skill_dir/SKILL.md" ]; then
        mkdir -p "$PUBLISH_DIR/skills/$skill_name"
        cp "$skill_dir/SKILL.md" "$PUBLISH_DIR/skills/$skill_name/SKILL.md"
    fi
done

echo "Published $(find "$PUBLISH_DIR" -name '*.md' | wc -l) markdown files to $PUBLISH_DIR/"
