---
name: postgres-cli
description: "CLI-based PostgreSQL expert using psql — no MCP required. Use for schema exploration, SQL queries, data analysis, performance diagnosis, write operations, and migrations. Trigger when user mentions database, SQL, tables, queries, schema, indexes, EXPLAIN, migrations, or any PostgreSQL work and no MCP Postgres server is available."
argument-hint: "[explore|query|analyze|perf|write|migrate] optional mode"
allowed-tools: Bash(psql*), Bash(pg_dump*), Bash(docker*), Read, Write, Glob, Grep
---

# Postgres CLI Expert

Token-efficient PostgreSQL skill using `psql` directly. Designed for environments without MCP Postgres.

## Phase 0: Prerequisites & Connection Discovery

### Client Detection

Before anything, verify `psql` is available:
```bash
psql --version 2>/dev/null || echo "NOT_FOUND"
```

If `psql` is not found, detect the platform and suggest installation:

| Platform | Install command |
|----------|----------------|
| macOS (Homebrew) | `brew install libpq && brew link --force libpq` |
| macOS (Postgres.app) | Add `/Applications/Postgres.app/Contents/Versions/latest/bin` to PATH |
| Debian/Ubuntu | `sudo apt-get install postgresql-client` |
| RHEL/Fedora | `sudo dnf install postgresql` |
| Alpine | `apk add postgresql-client` |
| Docker (no local install) | `docker exec -it <container> psql ...` (use the running Postgres container directly) |

If the user can't install `psql`, fall back to `docker exec` against a running Postgres container. Detect the container name from `docker ps`.

### Connection Discovery

Find the database connection automatically — don't ask the user unless all detection fails.

**Step 1 — Environment variables** (fastest, most reliable):
```bash
# Check in one shot
echo "DATABASE_URL=${DATABASE_URL:-unset} PGHOST=${PGHOST:-unset} PGDATABASE=${PGDATABASE:-unset} PGUSER=${PGUSER:-unset} PGPORT=${PGPORT:-unset}"
```
If `DATABASE_URL` is set, use it directly. If `PG*` vars are set, `psql` will pick them up automatically (no explicit connection string needed).

**Step 2 — Project config files** (scan common locations):
```bash
# Look for connection strings in project files
grep -rn --include='*.env' --include='*.env.*' --include='docker-compose*' --include='*.yml' --include='*.yaml' --include='*.toml' --include='*.json' --include='*.py' --include='*.js' --include='*.ts' --include='*.rb' -E '(DATABASE_URL|POSTGRES_|postgresql://|postgres://)' . 2>/dev/null | head -20
```
Parse the connection string from whichever file matches. Common patterns:
- `.env` / `.env.local` — `DATABASE_URL=postgres://user:pass@host:port/db`
- `docker-compose.yml` — `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` under a postgres service, with port mapping
- `config/database.yml` (Rails) — `host`, `database`, `username`, `password`
- `settings.py` (Django) — `DATABASES['default']`
- `knexfile.js` / `drizzle.config.ts` / `prisma/.env` — connection strings

**Step 3 — Docker containers** (if project uses Docker):
```bash
docker ps --filter "ancestor=postgres" --format "{{.Names}} {{.Ports}}" 2>/dev/null
```
If a Postgres container is running, extract the mapped port and connect as:
```bash
psql "postgres://postgres@localhost:<mapped-port>/postgres"
```
Might need the password from `docker-compose.yml` or `docker inspect`.

**Step 4 — Local Postgres**:
```bash
psql -l -tA 2>/dev/null | head -10
```
If `psql` connects without args, list databases and let the user pick.

**Step 5 — Ask the user** (last resort):
Only if all above steps fail. Ask for: host, port, database name, user, password.

### Store and test the connection

Once resolved, test the connection before proceeding:
```bash
DB="<resolved_connection_string>"
psql "$DB" -tA -c "SELECT 1"
```
If it fails, show the error and try the next detection method. If all methods fail, ask the user.

All queries use compact output: `psql "$DB" -tA -c "SQL"` (tuples-only, unaligned).
For human-readable tables: `psql "$DB" -c "SQL"` (expanded output when needed).

## Phase 1: Schema Warm-up

Check `{SKILL_PATH}/references/schema_cache.md` first.

**If cache is empty or stale**, discover schema:

```bash
# List tables
psql "$DB" -tA -c "SELECT schemaname||'.'||tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename"

# Describe each table (batch in one query for token efficiency)
psql "$DB" -tA -c "
SELECT c.table_name, c.column_name, c.data_type, c.is_nullable, c.column_default
FROM information_schema.columns c
WHERE c.table_schema='public'
ORDER BY c.table_name, c.ordinal_position"

# Row estimates + FK + enums in one shot
psql "$DB" -tA -F'|' -c "
SELECT relname, reltuples::bigint
FROM pg_class WHERE relkind='r' AND relnamespace='public'::regnamespace
ORDER BY relname"
```

Detect foreign keys:
```bash
psql "$DB" -tA -c "
SELECT tc.table_name, kcu.column_name, ccu.table_name AS ref_table, ccu.column_name AS ref_col
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu USING (constraint_name, table_schema)
JOIN information_schema.constraint_column_usage ccu USING (constraint_name, table_schema)
WHERE tc.constraint_type='FOREIGN KEY' AND tc.table_schema='public'"
```

Discover enums for columns matching `status|type|role|kind|state|category`:
```bash
psql "$DB" -tA -c "SELECT DISTINCT column_name, table_name FROM information_schema.columns WHERE table_schema='public' AND column_name ~ '(status|type|role|kind|state|category)'"
# Then: SELECT DISTINCT <col> FROM <table> LIMIT 20
```

Write enriched cache to `{SKILL_PATH}/references/schema_cache.md` with timestamp.

**Staleness check** (if cache exists): compare table list. Refresh if tables added/removed or user asks.

**Annotations** in cache:
- `SENSITIVE` — columns matching `email|phone|password|token|secret|ssn`
- `FK -> table.col` — foreign key targets
- `enum: val1, val2` — discovered distinct values
- `temporal` — `created_at`, `updated_at`, `deleted_at`

## Phase 2: Intent Classification

Classify into one mode:

| Mode | Signals |
|------|---------|
| **explore** | "what tables", "show schema", "describe", "structure" |
| **query** | "find", "get", "show me", "list", "SELECT" |
| **analyze** | "how many", "trend", "distribution", "average", "compare", "breakdown" |
| **perf** | "slow", "optimize", "EXPLAIN", "index", "performance" |
| **write** | "insert", "update", "delete", "add row", "change", "remove" |
| **migrate** | "add column", "create table", "alter", "rename", "drop", "migration" |

## Phase 3: Load Reference (only for current mode)

- **explore**: no reference needed, use cache
- **query** or **analyze**: read `{SKILL_PATH}/references/query-patterns.md`
- **perf**: read `{SKILL_PATH}/references/explain-guide.md`
- **write**: read `{SKILL_PATH}/references/write-ops.md`
- **migrate**: read `{SKILL_PATH}/references/migrations.md`

Load only the one file needed. Never preload all references.

## Phase 4: Clarify

Before executing:
- Ambiguous column names or business terms: ask
- Unknown enum values: discover with `SELECT DISTINCT`
- Complex queries (>2 JOINs, window functions, subqueries): propose SQL, wait for approval

## Phase 5: Execute

Every query starts with: `SET statement_timeout = '15s';`

### SQL Conventions
- Keywords UPPERCASE, identifiers lowercase
- Short aliases: `users u`, `orders o`
- CTEs over nested subqueries
- `LIMIT 10` default unless user specifies otherwise
- Never `SELECT *` — name columns explicitly
- SENSITIVE columns: `'***' AS column_name` in output
- UTC for all timestamps

### Mode-specific execution:

**explore**: Present schema from cache. No queries needed unless user asks deeper.

**query / analyze**: Build SQL, execute, format results. Use `psql -c` for readable tabular output.

**perf**:
```bash
psql "$DB" -c "EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) <query>"
```
Interpret the plan, identify bottlenecks, propose actionable fixes.

**write**: Safe write protocol:
1. Dry-run: `SELECT COUNT(*) FROM ... WHERE ...` to show scope
2. Propose the SQL
3. Wait for explicit "go" / confirmation
4. Execute in transaction:
```bash
psql "$DB" -c "BEGIN; <DML>; SELECT ... verification; COMMIT;"
```
5. On error: `ROLLBACK`, inspect table, correct once, no further retries

**migrate**: Generate UP + DOWN DDL scripts. Never auto-execute. Present for review.

### Safety rules (always apply)
- `statement_timeout = '15s'` on every query
- Write operations: explicit user confirmation required
- DELETE: WHERE clause mandatory + COUNT preview
- DROP/TRUNCATE: redirect to migrate mode, double-confirm
- SENSITIVE columns: anonymize in SELECT, require confirmation for writes
- Rollback on any error in transactions

## Phase 6: Post-execution

- Update schema cache if new discoveries were made
- On error: rollback, describe affected table, correct and retry once max

## Token Efficiency Rules

These rules keep context lean:
1. **Cache aggressively** — never re-discover schema if cache is fresh
2. **Load one reference max** — only the mode-specific file
3. **Use `-tA` output** — compact psql output for intermediate queries (counts, enums, schema discovery)
4. **Use `-c` output** — readable format only for final results shown to user
5. **Batch discovery queries** — use information_schema joins instead of per-table calls
6. **No redundant SELECTs** — if the cache answers the question, don't query
7. **Minimal error context** — on failure, show only the relevant error line + table structure
