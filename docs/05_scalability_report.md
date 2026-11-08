# CP4 – Scalability Report (Draft Before Large Dataset)

**Project:** OLX Buy & Sell Database  
**Database:** `olx_de_dbms`  
**Schema:** `olx`  
**PostgreSQL:** 18.6  
**Seed workload:** 120,000 listings  
**Status:** Seed measurements and architecture experiment recorded. Large-dataset results are pending the faculty-provided `large_data.zip` expected on 19 November 2026. This is a working draft, not the final CP4 report.

> **Integrity note:** No large-dataset timings, growth ratios, target pass/fail results, or large-dataset storage measurements are claimed in this draft. Fill those cells only after running the optimized workload against the faculty dataset and saving the matching raw plans.

## 1. Scope and methodology

The purpose of this phase is to assess how the optimized OLX workload behaves as the database grows from the 120,000-listing seed dataset to the approximately 20× large dataset. The large dataset is expected to contain approximately 2,400,000 listings, 4,191,000 chat messages, 1,197,000 chat threads, 1,400,000 favourites, and 1,000,000 users.

The seed comparison uses the CP3 optimized benchmark results in `benchmarks/results/optimized/summary.csv`. Those averages were produced using five runs per query. The large-dataset workload must use the optimized SQL only and the CP4 protocol of three `EXPLAIN (ANALYZE, BUFFERS)` runs per query, with write queries wrapped in `BEGIN` and `ROLLBACK`. Preserve all raw plans in `benchmarks/results/large/`.

For each query, calculate:

`Growth factor = large-dataset average (ms) / optimized seed average (ms)`

A growth factor near 1 means execution time stayed approximately constant; near 20 means it grew roughly in proportion to the expected data volume; greater than 20 means it grew faster than the data volume. Interpret these groups using the plans and the amount of data scanned, joined, sorted, or aggregated.

## 2. Optimized seed results and large-data target table

The following optimized seed averages are copied from `benchmarks/results/optimized/summary.csv`. The seed values are reference measurements, not large-dataset target results. Large averages, growth factors, target outcomes, and fixes must be filled after the large benchmark is run.

| Query | Type | Optimized seed avg (ms) | Large avg (ms) | Growth (large ÷ seed) | Large target | Meets target? / action |
|---|---|---:|---:|---:|---:|---|
| R01 | READ | 0.661 | Pending | Pending | < 5 ms | Pending |
| R02 | READ | 0.269 | Pending | Pending | < 5 ms | Pending |
| R03 | READ | 2.763 | Pending | Pending | < 5 ms | Pending |
| R04 | READ | 0.377 | Pending | Pending | < 5 ms | Pending |
| R05 | READ | 1.319 | Pending | Pending | < 5 ms | Pending |
| R06 | READ | 15.472 | Pending | Pending | < 5 ms | Pending |
| R07 | READ | 5.651 | Pending | Pending | < 5 ms | Pending |
| R08 | READ | 4.128 | Pending | Pending | < 5,000 ms | Pending |
| R09 | READ | 3.194 | Pending | Pending | < 5 ms | Pending |
| R10 | READ | 0.167 | Pending | Pending | < 250 ms | Pending |
| R11 | READ | 1.969 | Pending | Pending | < 250 ms | Pending |
| R12 | READ | 34.470 | Pending | Pending | < 5,000 ms | Pending |
| R13 | READ | 10.698 | Pending | Pending | < 250 ms | Pending |
| R14 | READ | 8.959 | Pending | Pending | < 5,000 ms | Pending |
| R15 | READ | 10.587 | Pending | Pending | < 5,000 ms | Pending |
| R16 | READ | 5.498 | Pending | Pending | < 250 ms | Pending |
| R17 | READ | 11.544 | Pending | Pending | < 5,000 ms | Pending |
| R18 | READ | 36.881 | Pending | Pending | < 5,000 ms | Pending |
| R19 | READ | 54.516 | Pending | Pending | < 5,000 ms | Pending |
| R20 | READ | 5.495 | Pending | Pending | < 5,000 ms | Pending |
| R21 | READ | 8.002 | Pending | Pending | < 5,000 ms | Pending |
| R22 | READ | 6.075 | Pending | Pending | < 250 ms | Pending |
| R23 | READ | 0.026 | Pending | Pending | < 5 ms | Pending |
| R24 | READ | 4.626 | Pending | Pending | < 5,000 ms | Pending |
| R25 | READ | 56.573 | Pending | Pending | < 5,000 ms | Pending |
| W01 | WRITE | 1.151 | Pending | Pending | < 5 ms | Pending |
| W02 | WRITE | 1.895 | Pending | Pending | < 5 ms | Pending |
| W03 | WRITE | 0.466 | Pending | Pending | < 5 ms | Pending |
| W04 | WRITE | 37.342 | Pending | Pending | < 1,000 ms | Pending |
| W05 | WRITE | 1.323 | Pending | Pending | < 5 ms | Pending |

### Target groups

- **Real-time / user-facing:** R01, R02, R03, R04, R05, R06, R07, R09, R23, W01, W02, W03, W05 — average under 5 ms.
- **Interactive tools:** R10, R11, R13, R16, R22 — average under 250 ms.
- **Reports and analytics:** R08, R12, R14, R15, R17, R18, R19, R20, R21, R24, R25 — average under 5,000 ms.
- **Batch jobs:** W04 — average under 1,000 ms.

## 3. Seed database storage baseline

Storage was measured in the `olx` schema after CP3 indexes were created. Table and index sizes are PostgreSQL relation-size measurements displayed with `pg_size_pretty`, so individual values are rounded.

| Table | Table size | Index size | Total size |
|---|---:|---:|---:|
| listings | 40 MB | 19 MB | 58 MB |
| chat_messages | 17 MB | 11 MB | 28 MB |
| users | 4,360 kB | 4,504 kB | 8,896 kB |
| chat_threads | 3,056 kB | 2,576 kB | 5,664 kB |
| favourites | 3,032 kB | 1,552 kB | 4,616 kB |
| offers | 1,536 kB | 456 kB | 2,024 kB |
| seller_ratings | 768 kB | 264 kB | 1,072 kB |
| reports | 640 kB | 192 kB | 864 kB |
| boost_packages | 8 kB | 16 kB | 24 kB |
| cities | 8 kB | 16 kB | 24 kB |
| categories | 8 kB | 16 kB | 24 kB |

The aggregate `olx` schema measurement was approximately 69 MB of table data, 39 MB of indexes, and 109 MB total. `pg_database_size('olx_de_dbms')` returned 200 MB. The database-wide value was recorded after creating the separate `olx_cp4` experiment schema; it is not a schema-only size and should not be compared to a future clean database without noting the scope difference.

For the large database, repeat the same per-table and aggregate queries and record total database size, table data, and index data. Keep the large and seed measurement scopes consistent.

## 4. Partitioning experiment: HASH by `listing_id`

### 4.1 Design and key constraint

An isolated test copy was created as `olx_cp4.listings`, partitioned by `HASH (listing_id)` into eight partitions (`MODULUS 8`, remainders 0 through 7). The original `olx.listings` and its referencing child tables were not changed. The test copy retained the table structure and indexes using `LIKE ... INCLUDING ALL`, restored its outgoing foreign keys to the OLX lookup tables, and copied the seed rows.

This key was chosen as a conservative demonstration because the existing primary key is `PRIMARY KEY (listing_id)` and the existing unique constraint is `UNIQUE (listing_id, seller_id)`. Both include `listing_id`. PostgreSQL requires every partition key column to be included in a partitioned table's primary-key or unique constraint; this is necessary because per-partition indexes cannot independently guarantee uniqueness across different partitions. See the PostgreSQL 18 documentation: [Table Partitioning – limitations and best practices](https://www.postgresql.org/docs/18/ddl-partitioning.html).

A production migration still needs a dependency and foreign-key migration plan. This experiment deliberately leaves the existing `chat_threads`, `offers`, `favourites`, `reports`, and `seller_ratings` foreign keys pointing to `olx.listings`; it does not swap the original table.

### 4.2 Row distribution

The copy contained 120,000 rows, matching the original table exactly. The distribution was:

| Partition | Listings |
|---|---:|
| listings_h0 | 15,118 |
| listings_h1 | 15,081 |
| listings_h2 | 15,093 |
| listings_h3 | 14,943 |
| listings_h4 | 14,927 |
| listings_h5 | 14,861 |
| listings_h6 | 14,898 |
| listings_h7 | 15,079 |
| **Total** | **120,000** |

The observed distribution is reasonably balanced: each partition held approximately 15,000 rows.

### 4.3 Partition pruning evidence

For `WHERE listing_id = 100871`, the partitioned plan used an index scan on `listings_h3` only. It did not scan the other seven partitions. The plan showed `Index Cond: (listing_id = 100871)` and execution time of 0.016 ms in the initial single-run comparison. This verifies partition pruning for a predicate on the hash key.

For a representative city/category search (`city_id = 1`, `category_id = 2`, `status = 'ACTIVE'`, ordered by `posted_at DESC`, limit 40), the plan used `Merge Append` with an index scan on each of the eight partitions. Because the predicate did not constrain `listing_id`, no partition could be pruned.

### 4.4 Repeated timing comparison

The same query was run three times against the original and partitioned copies, alternating order. These are microbenchmark measurements of two representative query shapes, not the official 30-query benchmark and not the final large-data benchmark.

**Direct lookup by listing_id = 100871**

| Run | Original (ms) | Partitioned (ms) |
|---|---:|---:|
| 1 | 0.031 | 0.009 |
| 2 | 0.004 | 0.006 |
| 3 | 0.003 | 0.003 |
| **Average** | **0.0127** | **0.0060** |
| **Median** | **0.004** | **0.006** |

The partitioned mean was lower, but the median was slightly higher. With such small timings, the first-run effect and cache state are material; this experiment does not prove a stable speedup. Both plans accessed three shared buffers.

**City/category search without the partition key**

| Run | Original (ms) | Partitioned (ms) |
|---|---:|---:|
| 1 | 0.055 | 0.212 |
| 2 | 0.020 | 0.047 |
| 3 | 0.019 | 0.036 |
| **Average** | **0.0313** | **0.0983** |
| **Median** | **0.020** | **0.047** |

The partitioned query was about 3.14× slower by mean in this small-seed experiment. The original plan used one index scan, while the partitioned plan used `Merge Append` and index scans across all eight partitions. This is evidence that HASH partitioning by `listing_id` does not help city/category browsing when the query has no predicate on the partition key.

### 4.5 Partitioned listing storage

| Design | Table storage | Index storage | Total storage |
|---|---:|---:|---:|
| Original `olx.listings` | 40 MB | 19 MB | 58 MB |
| Eight-partition `olx_cp4.listings` copy | 34 MB | 48 MB | 83 MB |

The partitioned copy used approximately 43% more total storage in this measurement, primarily because its partition-level indexes consumed more space (48 MB versus 19 MB). The displayed values are rounded. The smaller table-data figure for the copy should not be interpreted as compression or a guaranteed storage benefit.

### 4.6 Partitioning conclusion

The experiment verifies pruning for direct lookups on `listing_id`, but it also shows extra index storage and fan-out across all eight partitions for city/category searches. Therefore, HASH partitioning by `listing_id` is a validated demonstration and a possible fit for listing-ID-centric access, but it is not established as the best production strategy for the entire workload.

A RANGE strategy on `posted_at` could align better with time-window queries and old-data archival. However, the current primary key and foreign keys depend on `listing_id`; a range-partitioned design would need a carefully designed key and foreign-key change because PostgreSQL's partitioned primary-key/unique constraints must include the partition key. Test this alternative against the actual large workload before selecting it for production.

## 5. What to analyze after large-data execution

After the large dataset is loaded and `ANALYZE` has been run, inspect every query that misses its assigned target. Use the raw plans to identify whether the limiting operation is a sequential scan, large bitmap/heap scan, nested-loop repetition, hash join spill, sort spill, high buffer reads, or cross-table aggregation. Record each fix with its before-and-after plan and rerun the query three times.

Do not claim that a query broke at scale or that a fix worked until the corresponding large-data plan and timing exist.

## 6. Architecture proposal for 100× volume

The following is a design proposal, not an implemented or load-tested architecture. A simple 100× extrapolation from the seed row counts would mean roughly 12 million listings, 5 million users, 5.99 million chat threads, 20.95 million chat messages, and 7 million favourites. These are planning estimates, not supplied dataset counts.

### 6.1 Partitioning

Keep partitioning tied to measured predicates. The HASH(`listing_id`) experiment is operationally simple with the current primary key and demonstrated pruning for exact listing-ID lookups, but it did not prune the city/category browsing query and increased measured listing storage from 58 MB to 83 MB on the seed copy. At 100×, eight evenly balanced hash partitions would average roughly 1.5 million listings each, but the appropriate partition count must be selected using large-data plans, index sizes, memory, and maintenance tests rather than this arithmetic alone.

If retention and date-window access dominate, evaluate RANGE(`posted_at`) partitions (for example, monthly or quarterly) in a separate migration prototype. Before production adoption, redesign the key and every dependent foreign key so uniqueness remains enforceable across partitions. Demonstrate pruning on the real queries and validate inserts, updates, foreign keys, and archival operations.

### 6.2 Sharding

A city-based shard key would localize many local browsing queries, but a buyer and seller may live in different cities, and a chat thread references a listing and a buyer. Chat inbox, unread badge, responsiveness, and listing/user history queries could become cross-shard operations. Global search and cross-city analytics would also fan out.

A seller-based shard key would keep a seller's listings together, but buyer favourites, offers, and conversations can involve many sellers, so user-centric history and inbox queries would still span shards.

A listing-based hash shard key is a reasonable first design to evaluate because listing detail, offers, favourites, reports, and the chat thread for a listing can be routed using `listing_id`. Keep a global user directory for identity-to-shard lookup. A buyer's inbox would still need a fan-out across the shards containing their conversations; maintain a per-user conversation index or inbox projection to avoid querying every shard on each request. Cross-shard analytics should run as asynchronous aggregation jobs. These are proposed patterns and need a prototype before implementation.

### 6.3 Read replicas and caching

All writes (W01–W05) must go to the primary. Strongly consistent user-specific operations such as login (R23), My Ads (R05), chat inbox and unread badge (R06/R07), and immediately refreshed ad/detail state should use the primary when read-after-write consistency is required.

Potential replica candidates are read-heavy reports and analytics (R08, R12, R14, R15, R17, R18, R19, R20, R21, R24, R25), provided replica lag is acceptable. Public browsing/search queries (R01, R02, R03, R09) can use a read replica with a short cache TTL if slight staleness is acceptable. Reference data such as cities, categories, and boost-package metadata is a stronger cache candidate than user-specific chat or offer state. Cache invalidation must occur on listing, offer, and moderation changes; do not cache write results or imply strong consistency from an asynchronous replica.

### 6.4 Maintenance, archival, and summaries

Monitor `pg_stat_user_tables` for `n_live_tup`, `n_dead_tup`, `last_autovacuum`, `last_autoanalyze`, and modification counts. Monitor index growth and query plans as the data grows. Keep autovacuum enabled; evaluate table-specific vacuum/analyze scale factors for high-churn `listings`, `chat_messages`, and `offers` only after observing dead tuples and vacuum frequency. Run `ANALYZE` after bulk loading and significant data changes. Avoid setting arbitrary global memory or planner parameters to make benchmark plans look faster.

If time-based partitioning is adopted, detach/archive old listing partitions according to retention policy rather than issuing huge row-by-row deletes. Keep archived data queryable through a separate archive schema or storage tier if business and regulatory retention require it. For reports that tolerate delayed freshness, maintain summary tables or materialized views (for example, daily listing counts, category price summaries, and seller response aggregates) and document their refresh schedule and acceptable staleness.

## 7. Conclusion and remaining risks

The seed dataset confirms that the existing CP3 indexes support several important query patterns, while the partitioning experiment exposes both the benefit of key-based pruning and the cost of scanning multiple partitions for unrelated predicates. The measured seed OLX schema occupies approximately 109 MB including indexes; the database as a whole measured 200 MB after the isolated partitioning experiment was created.

A final readiness conclusion cannot be made until the 20× dataset has been loaded, all 30 optimized queries have three-run averages, target misses have been investigated, and large-dataset storage has been compared with the seed baseline. The largest remaining risks are query growth in chat and analytics workloads, write/index overhead, partition-key mismatch with browsing filters, and cross-shard user conversations.

## 8. Finalization checklist (complete after 19 November 2026)

- [ ] Create a separate large database and load the faculty-provided `large_data/` files.
- [ ] Run `ANALYZE` after loading and indexing.
- [ ] Run only `sql/06_optimized_queries.sql` using the required large benchmark method.
- [ ] Save all raw plans and `benchmarks/results/large/summary.csv`.
- [ ] Fill all 30 large averages, growth factors, target outcomes, and fixes in Section 2.
- [ ] Group queries into roughly constant, roughly 20×, and greater-than-20× growth with plan-based explanations.
- [ ] Record comparable large database, table, and index sizes.
- [ ] Add before/after large-data plans for every query fixed at scale.
- [ ] Revisit the 100× architecture using actual large-data measurements.
- [ ] Remove all pending placeholders and update the conclusion before final submission.
