---
name: postgres-expert
description: Use when the user asks questions about database state, requests data analysis, wants to explore table structure, or needs SQL queries executed via the MCP Postgres server
---

# Postgres Expert

Analyze data, explore schemas, and generate safe SQL queries using the `postgres` MCP server.

## MCP Tools

Before any query, check `{SKILL_PATH}/references/schema_cache.md` for cached schemas to avoid redundant MCP calls.

| Goal | Tool |
|------|------|
| List available tables | `list_tables` |
| Inspect columns and types | `describe_table` — never guess column names |
| Execute SQL | `query` |

## Workflow

1. Check schema cache (`references/schema_cache.md`) for the relevant tables
2. If missing, call `list_tables` → `describe_table` for needed tables
3. Write query following conventions below
4. Execute via `query`

## Security Rules

- **Read-only**: only `SELECT` statements — never `INSERT`, `UPDATE`, `DELETE`, `DROP`, `ALTER`
- **Always add `LIMIT 10`** unless the user explicitly asks for more
- **Never `SELECT *`** — name columns explicitly
- **Anonymize sensitive fields** inline: `SELECT id, '***' AS email FROM users`

## Error Handling

When a query fails, do not guess. Call `describe_table` on the involved table, read the error message carefully, then retry once with the corrected query.

## SQL Conventions

- Keywords in UPPERCASE (`SELECT`, `FROM`, `WHERE`, `JOIN`)
- Short explicit table aliases (`users u`, `orders o`)
- Prefer CTEs (`WITH ... AS (...)`) over nested subqueries for readability
- Always use UTC for date/time operations
