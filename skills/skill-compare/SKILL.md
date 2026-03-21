---
name: skill-compare
description: "Compare competing skills from different providers side-by-side. Use when the user wants to compare, diff, or choose between two skills that solve the same problem — e.g. 'compare anthropics/skill-creator vs vercel-labs/skill-creator', 'which commit skill is better', 'diff these two skills'. Supports fast (structural overview) and deep (full behavioral analysis with references and scripts). Especially valuable when multiple providers offer skills for the same task and the user needs to pick one or understand the tradeoffs."
argument-hint: "<path-or-name-1> <path-or-name-2> [--deep]"
---

# Skill Compare

Compare competing skills from different providers using a fixed analysis grid. The primary use case is when multiple providers offer skills that solve the same problem (e.g., several `skill-creator` or `commit` implementations) and you need to understand how they differ in approach, quality, and tradeoffs. Every comparison follows the same axes in the same order, so results are consistent and comparable across runs.

## Input

The user provides two skills to compare. These can be:
- Local paths to SKILL.md files
- Installed skill names (resolve via `~/.claude/skills/` or project `skills/`)
- Skill names to look up with `find-skills` if paths aren't provided

If only names are given without paths, resolve them:
1. Check local `skills/` directories and `~/.claude/skills/`
2. If not found locally, use `find-skills` (if available) to locate them on the marketplace
3. For remote skills, fetch the SKILL.md content (and references/ in deep mode) using the provider's repo — typically `https://raw.githubusercontent.com/<owner>/<repo>/main/skills/<skill-name>/SKILL.md`

When comparing skills from different providers (the most common case), expect different conventions and structures. The analysis grid is designed to normalize these differences into comparable dimensions.

## Mode Selection

- **`fast`** (default): Read only the two SKILL.md files. Quick structural comparison.
- **`deep`**: Read SKILL.md + all bundled resources (`references/`, `scripts/`, `assets/`). Full behavioral analysis.

The user can specify mode with `--deep` flag or by saying "deep comparison" / "in depth". Default is fast.

## Analysis Grid

Both modes use the same core axes, evaluated in this exact order:

### Core Axes (both modes)

| # | Axis | What to evaluate |
|---|------|-----------------|
| 1 | **Intent** | What problem does each skill solve? Are they targeting the same need or adjacent ones? |
| 2 | **Trigger** | How does each skill get activated? Compare the `description` frontmatter — what phrases/contexts would trigger one vs the other? Are there overlaps or gaps? |
| 3 | **Architecture** | Linear workflow vs branching logic. Does it use references, scripts, assets? How is the skill structured internally? |
| 4 | **Constraints** | Model override, allowed-tools restrictions, external dependencies, required MCPs. What does each skill need to run? |
| 5 | **Surface** | Line count of SKILL.md, number of reference files, ratio of instructions to loaded context. How heavy is each skill? |
| 6 | **Output** | What does the skill concretely produce? Files, reports, code, side effects? |

### Extended Axes (deep mode only)

| # | Axis | What to evaluate |
|---|------|-----------------|
| 7 | **Philosophy** | Rigid step-by-step vs flexible guidance. How much autonomy does the skill give the model? Does it explain *why* or just dictate *what*? |
| 8 | **Robustness** | Edge case handling, fallbacks, error paths. What happens when input is unexpected? |
| 9 | **Extensibility** | How easy is it to add new domains, variants, or integrations? Is it modular? |
| 10 | **Token Efficiency** | Progressive disclosure vs everything-in-context. Does it load references lazily? How much context does it consume? |
| 11 | **Examples** | Quality, coverage, and realism of included examples. Do they teach by showing? |

## Output Format

Structure the report exactly like this:

```markdown
# Skill Comparison: [Skill A] vs [Skill B]

**Mode:** fast | deep

## Summary Table

| Axis | [Skill A] | [Skill B] |
|------|-----------|-----------|
| Intent | ... | ... |
| Trigger | ... | ... |
| ... | ... | ... |

## Detailed Analysis

### 1. Intent
[2-3 sentences per skill, then a comparison note]

### 2. Trigger
[Same structure]

...

## Verdict

**Relationship:** complementary | competing | orthogonal

[One paragraph explaining the verdict — when to use each, or whether they can coexist. Be specific about use cases where one wins over the other.]
```

## find-skills Integration

If the `find-skills` skill is available, use it in two scenarios:

1. **Locating skills**: When the user provides skill names but not paths, search the marketplace.
2. **Suggesting alternatives** (deep mode only): After the analysis, if both skills share a weakness on a specific axis, search for a complementary skill that fills that gap. Frame it as: *"Neither skill handles [X] well — [suggested-skill] from the marketplace might complement either one."*

Only suggest alternatives when there's a genuine gap. Don't force suggestions.

## Guidelines

- Stay objective. Each axis has observable criteria — report what you see, not what you prefer.
- When skills are from different providers or ecosystems, note ecosystem-specific conventions but don't penalize for them.
- If a skill is minimal on an axis (e.g., no error handling), say so plainly rather than speculating about intent.
- For the verdict, "competing" means a user would choose one OR the other. "Complementary" means they solve different parts of the same problem. "Orthogonal" means they have nothing to do with each other.
