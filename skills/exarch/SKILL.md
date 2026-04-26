---
name: exarch
description: Analyzes project architecture and produces ASCII state machine and sequence diagrams for a codebase or feature. Use when the user asks to explain a project, analyze its architecture, trace an entrypoint, show a state machine, or generate a sequence diagram.
argument-hint: [codebase root | feature path | empty for current project]
---

# Architecture Explainer

Analyze project architecture and produce ASCII state machine and sequence diagrams for the target codebase or feature.

Target: `$ARGUMENTS`

## Workflow

Copy this checklist and check off items as you complete them:

```
Architecture Analysis:
- [ ] Step 1: Analyze project composition
- [ ] Step 2: Locate entrypoint
- [ ] Step 3: Build state machine graph
- [ ] Step 4: Generate sequence diagram
- [ ] Step 5: Synthesize output
```

### Step 1: Analyze project composition

Run: `tokei 2>/dev/null || echo 'tokei not installed'`

If tokei is unavailable, use Glob to count files by extension and estimate language composition.

Read the first matching package manifest:
- `package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `requirements.txt`, `pom.xml`, `build.gradle`

Identify the framework from config files (`next.config.js`, `vite.config.ts`, `astro.config.mjs`, `nuxt.config.ts`, `Dockerfile`, `Procfile`) and directory structure.

### Step 2: Locate entrypoint

If `$ARGUMENTS` names a feature or module, locate it first.

Otherwise search for the main entrypoint in this order:
1. `main` field in the package manifest
2. Conventional files: `main.*`, `index.*`, `app.*`, `cmd/main.go`
3. Framework entries: `pages/_app.tsx`, `app/layout.tsx`, `src/main.rs`, `manage.py`, `wsgi.py`

From the entrypoint, trace initialization, configuration loading, service bootstrap, and the main event loop or request handler.

If no entrypoint is found and `$ARGUMENTS` is empty, ask the user to specify a target rather than guessing.

### Step 3: Build state machine graph

Analyze the target for:
- State variables
- Transition triggers
- Guards
- Side effects
- Terminal states

Generate an ASCII directed graph using box-drawing characters (`─ │ ┌ ┐ └ ┘ ├ ┤ ┬ ┴ ┼ ► ◄ ▲ ▼`). Max 80 chars wide. Show cycles where they exist.

### Step 4: Generate sequence diagram

Identify actors: client, controllers, services, data layer, external APIs.

Generate an ASCII sequence diagram with vertical lifelines and arrows showing control flow between actors. Max 80 chars wide.

### Step 5: Synthesize output

Open with this header template:

```
╔════════════════════════════════════════╗
║ PROJECT: <name>                        ║
╠════════════════════════════════════════╣
║ Language: <primary>                    ║
║ Framework: <detected>                  ║
║ Type: <CLI/API/Web/Library>            ║
╚════════════════════════════════════════╝
```

Then output, in this order:
1. **Stack summary** — language, framework, major libraries, build tools, test framework
2. **State machine diagram** — directed graph from Step 3
3. **Sequence diagram** — control flow from Step 4
4. **Key files** — entrypoint, config, controller, service paths, formatted as `path:line`

## Constraints

- ASCII diagrams only (no Mermaid, no images), max 80 chars wide
- For large projects, focus on the specified feature path rather than the whole codebase
- Use forward slashes in all paths
