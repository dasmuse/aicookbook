---
name: postgres-expert
description: Use when the user asks about database state, data analysis, schema exploration, SQL queries, performance diagnosis, migrations, or data writes via the MCP Postgres server
argument-hint: "[question about your database] — or force a mode: explore|query|analyze|perf|write|migrate"
---

# Postgres Expert

Context-aware database expert using the `postgres` MCP server. Understands schema, business context, and generates safe, relevant SQL.

## MCP Tools

| Goal | Tool |
|------|------|
| List available tables | `list_tables` |
| Inspect columns and types | `describe_table` — never guess column names |
| Execute any SQL | `query` — all operations (SELECT, EXPLAIN, INSERT, DDL) go through this |

## Workflow

### 1. Warm-up

Check `{SKILL_PATH}/references/schema_cache.md` for cached schemas.

**If cache is empty or missing:**
1. `list_tables` → get all tables
2. `describe_table` for each table
3. Discover enum values: `SELECT DISTINCT <col> FROM <table> LIMIT 30` for columns named `status`, `type`, `role`, `kind`
4. Row estimates: `SELECT relname, reltuples::bigint FROM pg_class WHERE relname IN (...)`
5. FK detection: query `information_schema.table_constraints` + `key_column_usage` + `constraint_column_usage` WHERE `constraint_type = 'FOREIGN KEY'`. Fall back to `*_id` heuristic if inaccessible.
6. Table descriptions: `SELECT relname, obj_description(oid) FROM pg_class WHERE relname IN (...)`. Leave blank if no comment set.
7. Write enriched cache to `{SKILL_PATH}/references/schema_cache.md`

**If cache exists, run staleness check:**
1. Try: `SELECT schemaname, tablename FROM pg_stat_user_tables WHERE last_ddl_time > '<Last updated timestamp from cache header>'`
   - If this returns rows → those tables changed, re-run `describe_table` on them and update cache
   - If this query fails (column not available) → fall back to step 2
2. Fallback: compare `list_tables` output against cached table list
   - If tables were added or removed → re-run full discovery
3. If user says "refresh schema" → re-run full discovery
4. Implicit refresh: if any `describe_table` call during the session returns columns that differ from the cache → update cache for that table

**Annotations to apply when writing cache:**
- `SENSITIVE`: columns matching email/phone/password/token/secret patterns
- `temporal`: created_at/updated_at/deleted_at columns
- `FK → table.col`: from information_schema or `*_id` heuristic
- `enum: val1, val2, ...`: from SELECT DISTINCT results

### 2. Classify Intent

Determine the mode from the user's request. If the user passed an explicit mode argument, use it. Otherwise classify implicitly:

| Mode | Signals |
|------|---------|
| `explore` | "show me the tables", "what columns", "structure", "schema" |
| `query` | "get me", "show me data", "list the", "find", "which rows" |
| `analyze` | "how many", "trend", "distribution", "average", "compare", "per month" |
| `perf` | "slow", "performance", "optimize", "index", "explain" |
| `write` | "insert", "update", "change", "set", "add a row", "delete", "remove" |
| `migrate` | "add a column", "create table", "rename", "alter", "migration", "DDL" |

If ambiguous, ask the user before proceeding.

### 3. Load Reference

| Mode | Read file | Notes |
|------|-----------|-------|
| `explore` | (none) | Schema cache is sufficient |
| `query` | `{SKILL_PATH}/references/query-patterns.md` | JOINs, CTEs, anti-patterns |
| `analyze` | `{SKILL_PATH}/references/query-patterns.md` | Aggregations, window functions |
| `perf` | `{SKILL_PATH}/references/explain-guide.md` | EXPLAIN interpretation |
| `write` | `{SKILL_PATH}/references/write-operations.md` | Confirmation protocol |
| `migrate` | `{SKILL_PATH}/references/migrations.md` | DDL generation |

### 4. Clarify Before Acting

- Ambiguous columns? → ask for business context
- Unknown enums not in cache? → `SELECT DISTINCT` first
- Complex query (>2 JOINs, nested subqueries, or window functions)? → propose the SQL to the user before execution

### 5. Execute

Prepend `SET statement_timeout = '15s';` before every query.

- **explore**: present schema info from cache, run `describe_table` if needed
- **query/analyze**: execute, format results
- **write**: show dry-run COUNT → propose SQL → wait for user "go" → `BEGIN` → execute → verification SELECT → `COMMIT`
- **perf**: run `EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)`, interpret results
- **migrate**: generate UP + DOWN DDL, never execute without explicit user approval

### 6. Post-Execution

- Update schema cache if new info was discovered (including when `describe_table` returns columns that differ from cache — implicit refresh)
- On error:
  - If inside a transaction → `ROLLBACK` first
  - `describe_table` on involved tables
  - Correct query and retry once
  - If retry fails → report error, do not retry further

## Security Rules

These apply in ALL modes, always:

- `SET statement_timeout = '15s'` before every query
- `LIMIT 10` default on all SELECT unless user explicitly asks for more
- Never `SELECT *` — always name columns explicitly
- Columns marked SENSITIVE in cache: anonymize inline (`'***' AS email`) in SELECT output
- Write operations: never without explicit user confirmation
- DELETE: WHERE clause mandatory + COUNT preview before execution
- Migrate DDL: propose only, never auto-execute
- Sensitive columns can be written to only with explicit confirmation; anonymization applies to SELECT only

## SQL Conventions

- Keywords in UPPERCASE (`SELECT`, `FROM`, `WHERE`, `JOIN`)
- Short explicit table aliases (`users u`, `orders o`)
- CTEs (`WITH ... AS (...)`) over nested subqueries
- UTC for all date/time operations
