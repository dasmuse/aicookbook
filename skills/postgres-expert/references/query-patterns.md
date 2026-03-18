# Query Patterns

## JOIN strategies

Use FK info from schema_cache.md to determine valid join columns. Always qualify every column with a table alias.

- **INNER JOIN** — return only rows that match on both sides. Use when the related row is mandatory (e.g. every order has a user).
- **LEFT JOIN** — return all rows from the left table, NULLs on the right when no match. Use for optional relationships (e.g. users who may have no orders).
- **LATERAL JOIN** — evaluate a subquery per row of the driving table. Use for "top-N per group" or when the subquery references outer columns.

```sql
-- INNER: orders with their user
SELECT o.id, o.total, u.email
FROM orders o
INNER JOIN users u ON u.id = o.user_id
LIMIT 10;

-- LEFT: users and their order count (including users with 0 orders)
SELECT u.id, u.email, COUNT(o.id) AS order_count
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.email
LIMIT 10;

-- LATERAL: most recent order per user
SELECT u.id, u.email, last_order.created_at
FROM users u
LEFT JOIN LATERAL (
    SELECT o.created_at
    FROM orders o
    WHERE o.user_id = u.id
    ORDER BY o.created_at DESC
    LIMIT 1
) AS last_order ON true
LIMIT 10;
```

## Aggregations

### GROUP BY with HAVING

```sql
SELECT u.id, u.email, SUM(o.total) AS lifetime_value
FROM users u
INNER JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.email
HAVING SUM(o.total) > 1000
ORDER BY lifetime_value DESC
LIMIT 10;
```

### Standard aggregate functions

```sql
SELECT
    COUNT(*)                    AS total_rows,
    COUNT(DISTINCT user_id)     AS unique_users,
    SUM(total)                  AS revenue,
    AVG(total)                  AS avg_order_value,
    MIN(total)                  AS min_order,
    MAX(total)                  AS max_order
FROM orders;
```

### Window functions

```sql
SELECT
    o.id,
    o.user_id,
    o.total,
    ROW_NUMBER() OVER (PARTITION BY o.user_id ORDER BY o.created_at DESC)    AS rn,
    RANK()       OVER (PARTITION BY o.user_id ORDER BY o.total DESC)         AS revenue_rank,
    LAG(o.total) OVER (PARTITION BY o.user_id ORDER BY o.created_at)         AS prev_order_total,
    LEAD(o.total) OVER (PARTITION BY o.user_id ORDER BY o.created_at)        AS next_order_total,
    NTILE(4)     OVER (ORDER BY o.total)                                      AS quartile,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY o.total) OVER ()             AS median_total,
    percentile_disc(0.9) WITHIN GROUP (ORDER BY o.total) OVER ()             AS p90_total
FROM orders o
LIMIT 10;
```

## Temporal analysis

### Grouping by period

```sql
SELECT
    date_trunc('month', o.created_at) AS month,
    COUNT(*)                           AS order_count,
    SUM(o.total)                       AS revenue
FROM orders o
WHERE o.created_at >= now() - interval '12 months'
GROUP BY 1
ORDER BY 1;
```

### Filling date gaps with generate_series

Without `generate_series`, months with zero orders are silently omitted.

```sql
WITH months AS (
    SELECT generate_series(
        date_trunc('month', now() - interval '11 months'),
        date_trunc('month', now()),
        interval '1 month'
    ) AS month
),
monthly AS (
    SELECT date_trunc('month', o.created_at) AS month, COUNT(*) AS order_count
    FROM orders o
    GROUP BY 1
)
SELECT m.month, COALESCE(mo.order_count, 0) AS order_count
FROM months m
LEFT JOIN monthly mo ON mo.month = m.month
ORDER BY m.month;
```

### Period-over-period using LAG

```sql
WITH monthly AS (
    SELECT
        date_trunc('month', o.created_at) AS month,
        SUM(o.total) AS revenue
    FROM orders o
    GROUP BY 1
)
SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month)                                   AS prev_revenue,
    revenue - LAG(revenue) OVER (ORDER BY month)                         AS delta,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0),
        2
    ) AS pct_change
FROM monthly
ORDER BY month;
```

## Distributions

### Histogram with width_bucket

```sql
SELECT
    width_bucket(total, 0, 500, 10) AS bucket,
    numrange(
        (width_bucket(total, 0, 500, 10) - 1) * 50,
        width_bucket(total, 0, 500, 10) * 50
    ) AS range,
    COUNT(*) AS frequency
FROM orders
WHERE total BETWEEN 0 AND 500
GROUP BY 1
ORDER BY 1;
```

### Descriptive statistics

```sql
SELECT
    AVG(total)                                              AS mean,
    STDDEV(total)                                           AS stddev,
    percentile_cont(0.25) WITHIN GROUP (ORDER BY total)    AS p25,
    percentile_cont(0.5)  WITHIN GROUP (ORDER BY total)    AS median,
    percentile_cont(0.75) WITHIN GROUP (ORDER BY total)    AS p75,
    percentile_cont(0.95) WITHIN GROUP (ORDER BY total)    AS p95
FROM orders;
```

## Anti-patterns to avoid

### Subquery in WHERE instead of JOIN

```sql
-- BAD: correlated subquery re-executes per row
SELECT o.id, o.total
FROM orders o
WHERE o.user_id IN (SELECT id FROM users WHERE country = 'FR');

-- GOOD: single join pass
SELECT o.id, o.total
FROM orders o
INNER JOIN users u ON u.id = o.user_id AND u.country = 'FR';
```

### N+1 pattern

```sql
-- BAD: fetch order IDs, then query each user individually in application code
-- Batch with IN or JOIN instead:
SELECT o.id, o.total, u.email
FROM orders o
INNER JOIN users u ON u.id = o.user_id
WHERE o.id = ANY(ARRAY[1, 2, 3, ...]);
```

### DISTINCT as a band-aid for a broken join

```sql
-- BAD: DISTINCT hides that the join produces duplicate rows
SELECT DISTINCT u.id, u.email
FROM users u
JOIN order_items oi ON oi.user_id = u.id;

-- GOOD: fix the join — aggregate or use EXISTS
SELECT u.id, u.email
FROM users u
WHERE EXISTS (SELECT 1 FROM order_items oi WHERE oi.user_id = u.id);
```

### Missing GROUP BY columns

```sql
-- BAD: non-aggregated column not in GROUP BY (error in standard SQL)
SELECT u.id, u.email, COUNT(o.id)
FROM users u JOIN orders o ON o.user_id = u.id
GROUP BY u.id;  -- email must also be listed

-- GOOD
SELECT u.id, u.email, COUNT(o.id) AS order_count
FROM users u JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.email;
```

### Implicit type casts

```sql
-- BAD: casting indexed column prevents index use
SELECT id FROM orders WHERE created_at::date = '2024-01-01';

-- GOOD: cast the literal, keep the column intact
SELECT id FROM orders WHERE created_at >= '2024-01-01' AND created_at < '2024-01-02';
```
