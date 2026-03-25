# Migrations

## Pre-migration

Always inspect current state before proposing changes:
```bash
psql "$DB" -c "\d table_name"
```

## DDL Patterns

```sql
-- Create table
CREATE TABLE order_items (
  id BIGSERIAL PRIMARY KEY,
  order_id BIGINT NOT NULL REFERENCES orders(id),
  product_id BIGINT NOT NULL REFERENCES products(id),
  quantity INT NOT NULL DEFAULT 1,
  unit_price NUMERIC(10,2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Add column
ALTER TABLE orders ADD COLUMN discount_pct NUMERIC(5,2) DEFAULT 0;

-- Rename column
ALTER TABLE users RENAME COLUMN name TO full_name;

-- Change type (with USING for data conversion)
ALTER TABLE orders ALTER COLUMN status TYPE VARCHAR(50) USING status::VARCHAR(50);

-- Drop column
ALTER TABLE users DROP COLUMN legacy_field;

-- Create index
CREATE INDEX idx_orders_user_id ON orders (user_id);
CREATE UNIQUE INDEX uq_users_email ON users (email);
CREATE INDEX idx_orders_status_created ON orders (status, created_at);  -- composite
CREATE INDEX idx_orders_active ON orders (status) WHERE status != 'archived';  -- partial
```

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Tables | snake_case, plural | `order_items` |
| Columns | snake_case | `unit_price` |
| FK columns | `<table_singular>_id` | `order_id` |
| Temporal | `created_at`, `updated_at`, `deleted_at` | |
| Indexes | `idx_<table>_<cols>` | `idx_orders_user_id` |
| Unique | `uq_<table>_<cols>` | `uq_users_email` |
| FK constraints | `fk_<table>_<col>` | `fk_orders_user_id` |

## Output

- Always generate **UP** and **DOWN** scripts (DOWN = exact inverse)
- Plain SQL only, no ORM syntax
- Fenced code blocks for easy copy/paste
- **Never auto-execute** — present for review, wait for explicit approval
- Destructive operations (DROP TABLE, DROP COLUMN): require double confirmation
