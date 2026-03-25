# Skill Comparison: postgres-cli vs postgres-expert

**Mode:** deep

## Summary Table

| Axis | postgres-cli | postgres-expert |
|------|-------------|-----------------|
| **Intent** | PostgreSQL expert sans MCP, CLI-only | PostgreSQL expert via MCP server |
| **Trigger** | "no MCP Postgres server is available" | "via the MCP Postgres server" |
| **Architecture** | 7 phases (Phase 0-6), linear, psql-based | 6 phases (1-6), linear, MCP tool-based |
| **Constraints** | Needs `psql` CLI (or Docker fallback), no MCP | Needs MCP Postgres server running |
| **Surface** | SKILL.md: 227 lines, refs: 4 files (253 lines) = **480 total** | SKILL.md: 118 lines, refs: 5 files (642 lines) = **760 total** |
| **Output** | SQL results via terminal, schema cache file | SQL results via MCP, schema cache file |
| **Philosophy** | Explicit command templates with token rationale | Structured workflow, explains why for safety |
| **Robustness** | psql detection + 5-step connection fallback chain | Assumes MCP is configured and running |
| **Extensibility** | Easy to add modes/refs, Docker fallback built in | Same modular ref structure |
| **Token Efficiency** | Explicit design goal: `-tA` output, batch queries, 7 efficiency rules | No explicit token strategy, verbose refs |
| **Examples** | Compact: patterns as one-liners or minimal blocks | Rich: full annotated SQL blocks with context |

## Detailed Analysis

### 1. Intent

Both skills solve the same problem: act as a PostgreSQL expert that can explore schema, write queries, analyze data, diagnose performance, handle writes safely, and generate migrations. **postgres-cli** targets environments where no MCP Postgres server is available and uses `psql` directly. **postgres-expert** is built around the MCP Postgres toolchain (`list_tables`, `describe_table`, `query`).

They are the same skill adapted to different execution environments.

### 2. Trigger

**postgres-expert** triggers on "MCP Postgres server" context. **postgres-cli** triggers when there's no MCP available. The descriptions are complementary but could collide if both are installed — the "no MCP server is available" condition in postgres-cli's description is ambiguous at trigger time (Claude can't reliably detect MCP availability from a description alone).

Risk: if both skills are installed, Claude may pick one arbitrarily. Consider making the trigger conditions more explicit.

### 3. Architecture

Both use the same 6-phase workflow (warm-up, classify, load ref, clarify, execute, post-execute). **postgres-cli** adds a **Phase 0** for client detection and connection discovery — a significant addition that handles 5 fallback strategies (env vars, project files, Docker containers, local psql, ask user). The expert version assumes MCP handles connection.

Same intent router, same mode set (explore/query/analyze/perf/write/migrate), same lazy reference loading pattern.

### 4. Constraints

| | postgres-cli | postgres-expert |
|---|---|---|
| Runtime dependency | `psql` binary (or Docker) | MCP Postgres server |
| Tool restrictions | `Bash(psql*)`, `Bash(pg_dump*)`, `Bash(docker*)`, Read, Write, Glob, Grep | None specified (uses MCP tools) |
| Model override | None | None |
| Connection | Auto-detected from env/files/docker | Handled by MCP config |

**postgres-cli** has a broader tool allowlist and more self-sufficiency. **postgres-expert** is lighter but dependent on external MCP setup.

### 5. Surface

| Metric | postgres-cli | postgres-expert |
|--------|-------------|-----------------|
| SKILL.md | 227 lines | 118 lines |
| Reference files | 4 (253 lines) | 5 (642 lines) |
| **Total loadable** | **480 lines** | **760 lines** |
| Max single-mode context | SKILL.md + 1 ref (~300 lines) | SKILL.md + 1 ref (~360 lines) |

**postgres-cli** has a longer SKILL.md (Phase 0 adds ~60 lines) but significantly shorter references (60% smaller). Net context per invocation is lower for postgres-cli in every mode.

### 6. Output

Both produce the same artifacts: SQL results displayed to the user, schema cache file, proposed DDL scripts. The execution path differs — postgres-cli shows raw terminal output from `psql`, while postgres-expert returns structured MCP tool results. Terminal output from `psql -c` is arguably more familiar to database practitioners.

### 7. Philosophy

**postgres-cli** is more prescriptive about *how* to execute — it provides exact bash commands with flags (`psql "$DB" -tA -c "..."`) and includes a dedicated "Token Efficiency Rules" section that explains the reasoning behind each optimization. **postgres-expert** focuses more on *what* to do, leaving the how to MCP tool mechanics. Both explain why safety rules matter.

postgres-cli's approach is better for skill execution because it reduces ambiguity — the model doesn't need to figure out psql flags.

### 8. Robustness

**postgres-cli wins significantly here.** The 5-step connection discovery chain with platform-specific psql installation guidance means it handles many more failure scenarios. The Docker fallback (`docker exec`) means it works even without a local psql install. **postgres-expert** assumes MCP is configured — if it's not, the skill fails immediately with no recovery path.

### 9. Extensibility

Both use the same modular reference architecture (add a file to `references/`, add a mode to the router). Equally extensible. postgres-cli's `allowed-tools` is more explicit, making it clearer what a new mode could use.

### 10. Token Efficiency

This is **postgres-cli's primary design goal** and its clearest advantage:

| Strategy | postgres-cli | postgres-expert |
|----------|-------------|-----------------|
| Compact psql output (`-tA`) | Yes, for intermediate queries | N/A (MCP controls output) |
| Batch schema discovery | Yes (single `information_schema.columns` query) | No (per-table `describe_table`) |
| Reference file size | 253 lines total | 642 lines total (2.5x larger) |
| Explicit efficiency rules | 7 documented rules | None |
| Output format control | `-tA` for machine, `-c` for human | MCP decides |

The batch schema discovery alone saves N tool calls (one per table) and their associated token overhead.

### 11. Examples

**postgres-expert's references are richer.** Its `query-patterns.md` (239 lines) has fully annotated SQL examples with context about when and why to use each pattern. postgres-cli's version (75 lines) achieves the same coverage with compact one-liner patterns and a summary table for anti-patterns. The expert version teaches more; the CLI version consumes fewer tokens. Trade-off depends on how much the executing model needs guidance.

## Verdict

**Relationship:** complementary

These skills solve the same problem via different execution paths. **postgres-expert** is the right choice when an MCP Postgres server is configured — it's leaner in its SKILL.md (118 vs 227 lines) and its richer reference files provide more teaching context. **postgres-cli** is the right choice when no MCP is available — it's self-sufficient, handles connection discovery, and its aggressive token optimization makes it cheaper per invocation.

**When postgres-cli wins:** No MCP setup, Docker-based development, CI/CD environments, token-constrained contexts, users who want to see the actual psql commands being run.

**When postgres-expert wins:** MCP Postgres is configured and running, the user benefits from richer reference examples, structured MCP tool output is preferred.

**Coexistence concern:** If both are installed, the trigger descriptions may compete. Consider making postgres-cli trigger only when MCP tools are explicitly unavailable, or use a priority mechanism.
