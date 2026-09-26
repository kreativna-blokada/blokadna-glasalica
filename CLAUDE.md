# Glasalica — Godot 4.6 (mobile-first) game

## Layout
- `android/` — exported Android build; never lint/edit
- `!project/art/` — assets
- `project.godot` — root; renderer `mobile`, viewport 1920x1080 keep_height
- `!project/build/config/` — pure configuration only, no logic: `Configs`, `Globals`, `Signals` autoloads

## Tooling
- Godot CLI: `godot` (symlink to Godot.app)
- Parse check: `godot --headless --path . --check-only -s <script.gd>`
- MCP `godot` (godot-mcp) — use for running the project, capturing debug output, scene edits
- Plugin `godot-prompter` — Godot skills; use `godot-code-reviewer` agent for architecture/idiom review

## Definition of done
1. Project runs without errors in console
2. Review pass (`/code-review` + godot-code-reviewer) addressed

## Conventions
- Follow Godot GDScript style guide
- Signals via `Signals` autoload; shared constants/enums in `Globals`

## GodotPrompter
- Before implementing any Godot system, invoke the matching `godot-prompter:*` skill (index: `godot-prompter:using-godot-prompter`). Applies to subagents too.
