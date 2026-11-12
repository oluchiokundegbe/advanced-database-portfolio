# Portfolio 2 — Query Processing and Optimisation

**Case study:** ParcelPark | **DBMS:** PostgreSQL 17

## Aim
To find slow queries in realistic ParcelPark workloads by reading their execution plans, fix them with targeted optimisations, and measure the improvement.

## Files and run order

| # | File | Purpose |
|---|---|---|
| 1 | `01_generate_data.sql` | Generates a large dataset: 50,000 customers, 200,000 parcels, 20,000 trips, ~1 million tracking events and ~200,000 payments |
| 2 | `02_queries.sql` | Five real business queries (Q1–Q5) and their results |
| 3 | `03_explain_before.sql` | `EXPLAIN (ANALYZE, BUFFERS)` for each query **before** optimisation |
| 4 | `04_indexes.sql` | Four targeted indexes, plus their disk cost |
| 5 | `05_explain_after.sql` | The same plans **after** indexing |
| 6 | `06_materialized_view.sql` | A second technique for Q4, where indexes were not enough |
| — | `screenshots/` | Evidence |

Requires Portfolio 1 (`schema.sql` + `seed.sql`) to be loaded first. Each EXPLAIN was run twice and the second run recorded, so the comparison is not distorted by a cold cache.

## The five queries

| Query | Business purpose | Who uses it |
|---|---|---|
| Q1 | Look up a parcel by tracking code | Customers (most frequent query) |
| Q2 | Full tracking history of a parcel | Customers, agents |
| Q3 | All parcels sent by a customer (search by phone) | Park agents |
| Q4 | Monthly revenue per origin park | Management |
| Q5 | Delay alert: parcels in transit for over 3 days to a park | Destination park supervisors |

## Results

| Query | Plan before | Time before (ms) | Optimisation | Plan after | Time after (ms) | Speed-up |
|---|---|---|---|---|---|---|
| Q1 | Index Scan (`parcel_tracking_code_key`) | 0.396 | None needed | Index Scan | 0.178 | — |
| Q2 | **Parallel Seq Scan** on `tracking_event` (~1M rows) | 141.541 | `idx_event_parcel_time (parcel_id, event_time)` | Bitmap Index Scan | 0.923 | 153× |
| Q3 | **Parallel Seq Scan** on `parcel` (200k rows) | 116.605 | `idx_parcel_sender (sender_id)` | Bitmap Index Scan | 0.141 | 827× |
| Q4 | Seq Scans + Hash Join + aggregate | 266.848 | `idx_parcel_created` → **modest gain only** | Bitmap scan on parcel, still Seq Scan on payment | 121.721 | 2.2× |
| Q4 (v2) | — | — | Materialized view `mv_monthly_park_revenue` | Seq Scan on a ~220-row summary | 0.051 | 5,232× |
| Q5 | **Parallel Seq Scan** on `parcel` | 372.467 | Partial index `idx_parcel_in_transit` | Index Scan | 0.166  | 2,244× |

**Index cost** (from `04_indexes.sql`):

| Index | Size |
|---|---|
| `idx_event_parcel_time` | 32 MB |
| `idx_parcel_created` | 4408 kB |
| `idx_parcel_sender` | 2552 kB |
| `idx_parcel_in_transit` (partial) | 632 kB |

## Analysis

**Q1 was already fast.** PostgreSQL automatically creates a B-tree index for every PRIMARY KEY and UNIQUE constraint. Because `tracking_code` was declared UNIQUE in Portfolio 1, the most important customer query was efficient from day one. Good constraint design is also performance design.

**Q2, Q3 and Q5 show the classic missing-index problem.** Before indexing, the planner had no way to jump to the rows it needed. It read every row in the table with a *Sequential Scan*, which was split across worker processes as a *Parallel Seq Scan*, and threw most of them away. In Q2 it scanned about a million tracking events to return just 6.
- **Q3:** unlike some DBMSs, PostgreSQL does **not** automatically index foreign-key columns, so `parcel.sender_id` needed an index added by hand.
- **Q2:** the index is **composite** `(parcel_id, event_time)`. It matches both the filter and the `ORDER BY`, so the matching rows come back already in time order.
- **Q5:** the index is **partial** (`WHERE current_status = 'in_transit'`). It covers only about 10% of parcels, which keeps it the smallest index while serving the delay alert perfectly.

**Q4 shows that indexes are not a cure-all.** The monthly report has to aggregate about 10% of all parcels and join them to the payments table. The new date index helped find October’s parcels, roughly halving the time (266.8 → 121.7 ms), but the planner still chose to read the entire `payment` table for a hash join. Because so many rows are needed, that is genuinely cheaper than about 20,000 separate index lookups. The fix was a different technique: a **materialized view** that pre-computes revenue per park per month. The report then reads about 220 summary rows instead of hundreds of thousands. The trade-off is **freshness**: the view is a snapshot, and it must be refreshed with `REFRESH MATERIALIZED VIEW`, for example nightly. That is acceptable for a management report but not for live tracking.

**Indexes have costs.** Every index uses disk space. The composite index on `tracking_event` is the largest, at a sizeable fraction of the table itself. Every index also has to be updated on every INSERT. `tracking_event` is ParcelPark's most write-heavy table, with a new row at every checkpoint, so only indexes that serve real, frequent queries were added there.

## How to read the plans (key terms)
- **Seq Scan:** reads the whole table, row by row.
- **Index Scan / Bitmap Index Scan:** uses an index to jump straight to the matching rows.
- **Hash Join:** builds an in-memory hash table from one input to join it with the other. This is efficient when many rows are involved.
- **cost=…:** the planner's estimate. **actual time=…:** the measured time. **rows=…:** the number of rows returned by that step.
- **Execution Time:** the total time spent running the query.
