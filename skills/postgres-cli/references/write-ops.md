# Write Operations

Core rule: never execute a write without explicit user confirmation.

## INSERT

1. Propose the INSERT statement
2. Wait for "go"
3. Execute in transaction with verification:
```bash
psql "$DB" -c "BEGIN; INSERT INTO table (...) VALUES (...); SELECT * FROM table WHERE <identify_new_row> LIMIT 5; COMMIT;"
```

## UPDATE

1. Show affected scope: `SELECT COUNT(*) FROM table WHERE <condition>`
2. Show sample: `SELECT <cols> FROM table WHERE <condition> LIMIT 5`
3. Propose UPDATE
4. Wait for "go"
5. Execute in transaction:
```bash
psql "$DB" -c "BEGIN; UPDATE table SET ... WHERE ...; SELECT <cols> FROM table WHERE <condition> LIMIT 5; COMMIT;"
```

WHERE clause is mandatory. No bare UPDATEs.

## DELETE

1. Show sample: `SELECT <cols> FROM table WHERE <condition> LIMIT 5`
2. Show count: `SELECT COUNT(*) FROM table WHERE <condition>`
3. Propose DELETE
4. Wait for "go"
5. Execute in transaction:
```bash
psql "$DB" -c "BEGIN; DELETE FROM table WHERE ...; COMMIT;"
```

WHERE clause is mandatory. No bare DELETEs.

## Error Handling

On any error during write:
1. ROLLBACK immediately
2. Inspect table structure: `\d table_name`
3. Correct the SQL and propose again
4. One retry max — if it fails again, report the error

## Forbidden

DROP, TRUNCATE, ALTER are not write operations — redirect to **migrate** mode.

## Sensitive Columns

Columns flagged SENSITIVE in schema cache require explicit user confirmation before writing.
Anonymization (`'***'`) applies only to SELECT output, not to write values.
