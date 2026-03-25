# Query Patterns Reference

## JOINs

```sql
-- INNER: matching rows only
SELECT u.name, o.total FROM users u JOIN orders o ON o.user_id = u.id WHERE o.status = 'paid';

-- LEFT: keep all left rows
SELECT u.name, COUNT(o.id) AS order_count FROM users u LEFT JOIN orders o ON o.user_id = u.id GROUP BY u.id, u.name;

-- LATERAL: correlated subquery as join (top-N per group)
SELECT u.name, r.* FROM users u
CROSS JOIN LATERAL (SELECT * FROM orders o WHERE o.user_id = u.id ORDER BY o.created_at DESC LIMIT 3) r;
```

## Aggregations

```sql
-- Basic: COUNT, SUM, AVG, MIN, MAX with GROUP BY + HAVING
SELECT status, COUNT(*), AVG(total) FROM orders GROUP BY status HAVING COUNT(*) > 10;
```

## Window Functions

```sql
-- Ranking
ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC)
RANK() OVER (ORDER BY total DESC)

-- Comparison
LAG(total) OVER (PARTITION BY user_id ORDER BY created_at)   -- previous row
LEAD(total) OVER (PARTITION BY user_id ORDER BY created_at)  -- next row

-- Distribution
NTILE(4) OVER (ORDER BY total)  -- quartiles
percent_rank() OVER (ORDER BY total)
```

## Temporal Analysis

```sql
-- Period grouping
SELECT date_trunc('month', created_at) AS month, COUNT(*) FROM orders GROUP BY 1 ORDER BY 1;

-- Gap filling with generate_series
SELECT d::date, COALESCE(c, 0) FROM generate_series('2024-01-01','2024-12-31','1 day'::interval) d
LEFT JOIN (SELECT created_at::date AS day, COUNT(*) c FROM orders GROUP BY 1) o ON o.day = d::date;

-- Period-over-period
WITH monthly AS (SELECT date_trunc('month', created_at) m, SUM(total) t FROM orders GROUP BY 1)
SELECT m, t, LAG(t) OVER (ORDER BY m) AS prev, round((t - LAG(t) OVER (ORDER BY m)) / LAG(t) OVER (ORDER BY m) * 100, 1) AS pct_change FROM monthly;
```

## Distributions

```sql
-- Histogram
SELECT width_bucket(total, 0, 1000, 10) AS bucket, COUNT(*) FROM orders GROUP BY 1 ORDER BY 1;

-- Descriptive stats
SELECT COUNT(*), AVG(total), STDDEV(total), MIN(total),
  percentile_cont(0.5) WITHIN GROUP (ORDER BY total) AS median,
  percentile_cont(0.95) WITHIN GROUP (ORDER BY total) AS p95, MAX(total)
FROM orders;
```

## Anti-patterns to Avoid

| Bad | Better | Why |
|-----|--------|-----|
| `WHERE id IN (SELECT ...)` on large sets | `JOIN` or `EXISTS` | Subquery re-evaluated per row |
| N+1 queries in a loop | Single JOIN query | Roundtrip overhead |
| `SELECT DISTINCT` to fix duplicates | Fix the JOIN | DISTINCT masks incorrect joins |
| Implicit type casts in WHERE | Explicit `::type` | Prevents index usage |
