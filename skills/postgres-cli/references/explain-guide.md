# EXPLAIN Guide

## Running

```bash
psql "$DB" -c "EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) <your_query>"
```

Always use ANALYZE + BUFFERS for real execution stats.

## Node Types — When to Worry

| Node | Normal | Problem |
|------|--------|---------|
| Seq Scan | Small table (<10k rows) or needs most rows | Large table + selective WHERE = missing index |
| Index Scan | Selective queries on indexed columns | Fine, this is good |
| Index Only Scan | All needed columns in index | High heap fetches = run VACUUM |
| Bitmap Scan | Medium selectivity | `lossy` blocks = low work_mem |
| Nested Loop | Small outer, indexed inner | Large outer = O(n*m), consider Hash Join |
| Hash Join | Large tables, equality joins | Batches > 1 = spilling to disk, raise work_mem |
| Merge Join | Pre-sorted data | High sort cost = missing index on sort column |
| Sort | Small datasets | `external merge` = spilling, raise work_mem or add index |

## Key Metrics

- **actual time**: Wall clock ms per iteration. Multiply by `loops` for total.
- **rows**: estimated vs actual. Mismatch >10x = stale stats, run `ANALYZE table`.
- **Buffers hit vs read**: `hit` = cache, `read` = disk. High `read` = cold cache or table too large for memory.
- **Planning time**: Usually <1ms. High = complex query or too many partitions.

## Diagnostic Patterns

**Seq Scan on large table + selective WHERE**:
```
-> Seq Scan on orders (rows=1000000)
     Filter: (status = 'cancelled')
     Rows Removed by Filter: 999500
```
Fix: `CREATE INDEX idx_orders_status ON orders (status);`

**Nested Loop with high outer count**:
```
-> Nested Loop (actual rows=50000)
   -> Seq Scan on users (rows=50000)
   -> Index Scan on orders (rows=1)
```
If inner lacks index: `CREATE INDEX idx_orders_user_id ON orders (user_id);`

**Row estimate mismatch**:
```
-> Index Scan (estimated rows=100, actual rows=50000)
```
Fix: `ANALYZE table_name;` or check for correlated columns.

## Recommendation Format

Always provide actionable SQL:
```sql
-- Problem: Seq Scan on orders (500k rows) filtering by status
-- Impact: ~2s scan reduced to ~5ms
CREATE INDEX idx_orders_status ON orders (status);
-- After: ANALYZE orders; then re-run EXPLAIN to verify
```
