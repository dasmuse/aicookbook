# EXPLAIN Guide

## How to run

Always execute via the `query` tool with full options:

```sql
SET statement_timeout = '15s';
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT ...;
```

`ANALYZE` runs the query for real — use on a representative dataset, not production under load. `BUFFERS` shows buffer cache hits vs disk reads. `FORMAT TEXT` is the most readable output.

## Node types

### Seq Scan
Reads every row in the table from disk in physical order.

- **Normal when**: table is small, or the query returns a large fraction of rows (>~5–10%).
- **Problem when**: table is large and the WHERE clause is selective — a missing index is likely.

### Index Scan
Follows an index to look up individual heap rows.

- **Normal when**: query is highly selective (few rows).
- **Problem when**: index exists but is not used — check for implicit casts or function calls on the indexed column.

### Index Only Scan
Satisfies the query entirely from the index without touching the heap.

- **Normal when**: all SELECTed columns are covered by the index.
- **Problem when**: high heap fetches in output means the visibility map is stale — run `VACUUM` on the table.

### Bitmap Scan
Builds an in-memory bitmap of matching pages, then fetches them in order.

- **Normal when**: query returns a moderate number of rows (between Seq Scan and Index Scan sweet spots).
- **Problem when**: `Bitmap Heap Scan` shows `Recheck Cond` with many lossy pages — index is too large for `work_mem`.

### Nested Loop
For each row from the outer loop, probe the inner side.

- **Normal when**: outer side is small and inner side has an index on the join column.
- **Problem when**: outer side is large — O(n×m) cost. Look for a missing index on the inner join column.

### Hash Join
Builds a hash table on the smaller side, probes it with the larger side.

- **Normal when**: no index on the join column, large result sets.
- **Problem when**: `Batches > 1` means the hash table spilled to disk — increase `work_mem`.

### Merge Join
Requires both sides sorted on the join column; merges them in order.

- **Normal when**: both sides are pre-sorted (e.g. from an index scan).
- **Problem when**: `Sort` nodes appear as children — the planner is paying sort cost to enable Merge Join; Hash Join may be cheaper.

### Sort
Sorts input rows.

- **Normal when**: ORDER BY, GROUP BY, or Merge Join requires it.
- **Problem when**: `Sort Method: external merge` means spill to disk — increase `work_mem` or add an index on the sort columns.

### Aggregate
Computes GROUP BY / aggregate functions.

- **Normal when**: expected after GROUP BY.
- **Problem when**: `Hash Aggregate` with high memory and many buckets — increase `work_mem`.

## Key metrics

| Metric | What to look at |
|--------|----------------|
| `actual time` | Wall clock per loop iteration (ms). Sum = `actual time * loops`. |
| `estimated cost` | Planner's estimate. Large divergence from actual rows signals stale stats. |
| `rows estimated vs actual` | Ratio > 10× is a red flag — stale statistics. |
| `Buffers: hit` | Pages served from shared buffer cache (fast). |
| `Buffers: read` | Pages fetched from disk (slow). High read on an indexed column = cold cache or missing index. |
| `loops` | Node was executed this many times. Multiply `actual time` by `loops` for total cost. |

## Common diagnostic patterns

### Seq Scan on a large table with a selective WHERE
```
Seq Scan on orders (cost=0.00..45231.00 rows=3 width=48) (actual rows=3 loops=1)
  Filter: (user_id = 42)
  Rows Removed by Filter: 1200000
```
**Diagnosis**: missing index on `orders.user_id`.
**Fix**: `CREATE INDEX idx_orders_user_id ON orders (user_id);`

### Nested Loop with high outer row count
```
Nested Loop (actual rows=150000 loops=1)
  -> Seq Scan on orders ...
  -> Index Scan on order_items using order_items_pkey ...
```
**Diagnosis**: outer side too large for Nested Loop; inner join column may lack an index.
**Fix**: add an index on the join column so the planner switches to Hash Join.

### Sort with high cost
```
Sort (cost=12543.22..12793.22 rows=100000)
  Sort Key: created_at DESC
```
**Diagnosis**: no index on the ORDER BY column.
**Fix**: `CREATE INDEX idx_orders_created_at ON orders (created_at DESC);`

### Rows estimated vs actual mismatch
```
Seq Scan on events (cost=0.00..1234.00 rows=1 width=32) (actual rows=98432 loops=1)
```
**Diagnosis**: planner estimated 1 row, got 98 432 — statistics are stale.
**Fix**: `ANALYZE events;`

## Recommendations format

After interpreting the plan, output actionable SQL:

```sql
-- Missing index on join/filter column
CREATE INDEX idx_orders_user_id ON orders (user_id);

-- Partial index for a common filtered query
CREATE INDEX idx_orders_pending ON orders (created_at)
WHERE status = 'pending';

-- Stale statistics
ANALYZE orders;
```

Always explain *why* each recommendation addresses the specific bottleneck observed in the plan.
