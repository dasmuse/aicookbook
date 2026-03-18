# Write Operations

## Core rule

Never execute a write (INSERT, UPDATE, DELETE) without explicit user confirmation. Show the user exactly what will happen before touching any data.

## INSERT workflow

1. Propose the INSERT statement in a fenced code block.
2. Wait for the user to say "go" (or equivalent explicit approval).
3. Execute in a transaction:

```sql
SET statement_timeout = '15s';
BEGIN;

INSERT INTO users (email, name, created_at)
VALUES ('alice@example.com', 'Alice', now());

-- Verification: show what was just inserted
SELECT id, email, name, created_at
FROM users
WHERE email = 'alice@example.com'
LIMIT 10;

COMMIT;
```

4. Show the verification SELECT results to the user.

## UPDATE workflow

1. **Dry-run**: show how many rows will be affected before touching anything.

```sql
SET statement_timeout = '15s';
SELECT COUNT(*) AS rows_to_update
FROM orders
WHERE status = 'pending' AND created_at < now() - interval '30 days';
```

2. Propose the UPDATE statement with the same WHERE clause.
3. Wait for user "go".
4. Execute in a transaction:

```sql
SET statement_timeout = '15s';
BEGIN;

UPDATE orders
SET status = 'expired', updated_at = now()
WHERE status = 'pending' AND created_at < now() - interval '30 days';

-- Verification: sample of affected rows
SELECT id, status, updated_at
FROM orders
WHERE status = 'expired' AND updated_at >= now() - interval '5 seconds'
LIMIT 10;

COMMIT;
```

WHERE clause is mandatory on every UPDATE — reject or refuse any UPDATE without one.

## DELETE workflow

Same as UPDATE, but show a **sample of rows to be deleted** before the COUNT.

1. **Row sample**:

```sql
SET statement_timeout = '15s';
SELECT id, email, created_at
FROM users
WHERE last_login < now() - interval '2 years'
LIMIT 5;
```

2. **Count**:

```sql
SELECT COUNT(*) AS rows_to_delete
FROM users
WHERE last_login < now() - interval '2 years';
```

3. Propose the DELETE statement.
4. Wait for user "go".
5. Execute in a transaction:

```sql
SET statement_timeout = '15s';
BEGIN;

DELETE FROM users
WHERE last_login < now() - interval '2 years';

-- Verification: confirm 0 rows remain matching the condition
SELECT COUNT(*) AS remaining
FROM users
WHERE last_login < now() - interval '2 years';

COMMIT;
```

WHERE clause is mandatory on every DELETE.

## Error handling

If any step fails mid-transaction:

1. Immediately `ROLLBACK` — before any diagnostic work.
2. Run `describe_table` on the involved tables to verify column names and types.
3. Correct the statement and retry **once**.
4. If the retry also fails, report the error to the user and stop. Do not retry further.

```sql
ROLLBACK;
-- then describe_table, then corrected statement
```

## Forbidden operations

DROP, TRUNCATE, and ALTER are **not handled here** — redirect to `migrate` mode. If the user requests one of these, say:

> This looks like a schema migration. Switch to migrate mode and I'll generate a safe UP/DOWN script for your review.

## Sensitive columns

Columns marked `SENSITIVE` in schema_cache.md (email, phone, password, token, secret patterns) can be written to only with **explicit user confirmation** that they understand the column is sensitive. Remind the user before the write confirmation step:

> Note: `email` is marked SENSITIVE in the schema cache. Confirm you want to write to this column.

Anonymization (`'***' AS email`) applies only to SELECT output, not to writes.
