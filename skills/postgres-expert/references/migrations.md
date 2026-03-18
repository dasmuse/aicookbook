# Migrations

## Pre-migration check

Always run `describe_table` on the target table before proposing any ALTER. Verify that the current column set, types, and constraints match your expectations. Never assume the schema matches the cache — a deployment may have run since the last warm-up.

## DDL generation

### CREATE TABLE

Include PK, NOT NULL constraints, FK references, and default values.

```sql
CREATE TABLE order_items (
    id          uuid        NOT NULL DEFAULT gen_random_uuid(),
    order_id    uuid        NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id  uuid        NOT NULL REFERENCES products(id),
    quantity    integer     NOT NULL DEFAULT 1,
    unit_price  numeric(10,2) NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (id)
);
```

### ALTER TABLE

```sql
-- Add column
ALTER TABLE users ADD COLUMN phone varchar(20);

-- Drop column
ALTER TABLE users DROP COLUMN phone;

-- Rename column
ALTER TABLE users RENAME COLUMN phone TO phone_number;

-- Change type (safe cast)
ALTER TABLE users ALTER COLUMN score TYPE numeric(8,2) USING score::numeric(8,2);
```

### CREATE INDEX

```sql
-- Regular
CREATE INDEX idx_orders_user_id ON orders (user_id);

-- Unique
CREATE UNIQUE INDEX idx_users_email ON users (email);

-- Partial (filter reduces index size and targets common query patterns)
CREATE INDEX idx_orders_pending_created ON orders (created_at)
WHERE status = 'pending';

-- Composite
CREATE INDEX idx_order_items_order_product ON order_items (order_id, product_id);
```

Naming convention: `idx_<table>_<columns>` — e.g. `idx_order_items_order_product`.

## Naming conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Tables | snake_case, plural | `order_items` |
| Columns | snake_case | `unit_price` |
| FK columns | `<referenced_table_singular>_id` | `order_id`, `user_id` |
| Temporal columns | `created_at`, `updated_at`, `deleted_at` | — |
| Indexes | `idx_<table>_<columns>` | `idx_orders_user_id` |
| Constraints | `fk_<table>_<column>`, `uq_<table>_<column>` | `fk_order_items_order_id` |

## UP and DOWN scripts

Always generate both. The DOWN script must be the exact inverse of UP — restoring the schema to its prior state.

```sql
-- UP
ALTER TABLE users ADD COLUMN phone varchar(20);
CREATE INDEX idx_users_phone ON users (phone);

-- DOWN
DROP INDEX IF EXISTS idx_users_phone;
ALTER TABLE users DROP COLUMN phone;
```

For CREATE TABLE, the inverse is DROP TABLE. For ADD COLUMN, the inverse is DROP COLUMN. For CREATE INDEX, the inverse is DROP INDEX.

## Output format

Plain SQL only — no ORM syntax, no framework migrations. Present as a fenced `sql` code block the user can copy and paste directly into their migration tooling.

```sql
-- UP
...

-- DOWN
...
```

## Execution rule

Never auto-execute DDL. Always:

1. Present the UP/DOWN script for review.
2. Wait for explicit user approval ("run it", "apply", "go", etc.).
3. For **destructive operations** (DROP COLUMN, DROP TABLE, DROP INDEX), confirm one additional time after the first approval:

> You're about to DROP COLUMN `phone` from `users`. This is irreversible unless you run the DOWN script. Confirm?

Only proceed after this second confirmation.
