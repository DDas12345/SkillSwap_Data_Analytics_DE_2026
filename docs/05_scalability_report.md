# CP4 / Phase 5 – Final Scalability Report

**Project:** OLX Buy & Sell Database
**Database:** `olx_de_dbms_large` (large dataset); `olx_de_dbms` (seed database)
**Schema:** `olx`
**PostgreSQL:** 18.7 (Postgres.app)
**Seed workload:** 120,000 listings
**Large workload:** 2,400,000 listings
**Report date:** 23 November 2026
**Status:** Large dataset loaded; all 30 optimized queries benchmarked with three runs each; final results and remaining target misses documented.

> **Measurement integrity:** The official large-workload results in this report are the three-run averages in `benchmarks/results/large/summary.csv`. The earlier, pre-optimization large-data baseline is preserved in `benchmarks/results/large_baseline/`. Targeted experiments are retained in their separate result folders and are not substituted for the final full-workload measurements.

## 1. Scope and methodology

The purpose of this phase is to assess how the optimized OLX workload behaves as the database grows from the 120,000-listing seed dataset to the faculty-provided large dataset.

The large dataset was loaded into a separate database, `olx_de_dbms_large`, leaving the seed database `olx_de_dbms` unchanged. The large dataset contains 10,974,400 rows across the 11 OLX tables:

| Table | Rows |
|---|---:|
| `boost_packages` | 6 |
| `cities` | 10 |
| `categories` | 12 |
| `users` | 1,000,000 |
| `listings` | 2,400,000 |
| `chat_threads` | 1,197,387 |
| `chat_messages` | 4,190,915 |
| `offers` | 399,105 |
| `favourites` | 1,399,998 |
| `reports` | 159,983 |
| `seller_ratings` | 226,984 |
| **Total** | **10,974,400** |

The large-data schema was created using `sql/01_schema.sql`. The large CSV files were loaded using `sql/02_load_large_data.sql`, which changes the data directory from `seed_data/` to `large_data/` while retaining the original COPY and ANALYZE structure. The original `sql/02_load_data.sql` was not modified.

The large database was indexed and analyzed before benchmarking. The official workload was run using:

```bash
bash ./benchmarks/run_benchmark.sh \
  olx_de_dbms_large \
  large \
  3 \
  sql/06_optimized_queries.sql
```

Each query has three measured runs. Write queries are executed inside transactions and rolled back by the benchmark harness. The final raw plans and summary are stored in `benchmarks/results/large/`. The earlier large-data baseline is stored separately in `benchmarks/results/large_baseline/`.

The optimized seed comparison uses `benchmarks/results/optimized/summary.csv`, whose averages were produced using five runs per query. The large workload uses three runs per query. Therefore, the growth factors below are useful comparative indicators, but the different run counts and possible cache/I/O variation mean they are not a perfectly controlled statistical comparison.

For each query:

`Growth factor = final large-dataset average (ms) / optimized seed average (ms)`

A factor near 1 indicates approximately stable execution time; near 20 indicates growth roughly proportional to the approximate 20× listing-volume increase; greater than 20 indicates faster-than-data-volume growth. Query-specific row counts and operations differ, so growth should be interpreted together with the execution plans and not as a universal scaling law.

## 2. Final large-data benchmark results and target outcomes

The following are the final full-workload averages from `benchmarks/results/large/summary.csv`, compared with the optimized seed averages.

| Query | Type | Optimized seed avg (ms) | Final large avg (ms) | Growth factor | Target | Result |
|---|---|---:|---:|---:|---:|---|
| R01 | READ | 0.661 | 0.198 | 0.30× | < 5 ms | Pass |
| R02 | READ | 0.269 | 4.671 | 17.36× | < 5 ms | Pass |
| R03 | READ | 2.763 | 19.247 | 6.97× | < 5 ms | **Miss** |
| R04 | READ | 0.377 | 0.393 | 1.04× | < 5 ms | Pass |
| R05 | READ | 1.319 | 0.070 | 0.05× | < 5 ms | Pass |
| R06 | READ | 15.472 | 1.368 | 0.09× | < 5 ms | Pass |
| R07 | READ | 5.651 | 0.327 | 0.06× | < 5 ms | Pass |
| R08 | READ | 4.128 | 63.652 | 15.42× | < 5,000 ms | Pass |
| R09 | READ | 3.194 | 0.380 | 0.12× | < 5 ms | Pass |
| R10 | READ | 0.167 | 3.367 | 20.16× | < 250 ms | Pass |
| R11 | READ | 1.969 | 25.743 | 13.07× | < 250 ms | Pass |
| R12 | READ | 34.470 | 791.775 | 22.97× | < 5,000 ms | Pass |
| R13 | READ | 10.698 | 217.040 | 20.29× | < 250 ms | Pass |
| R14 | READ | 8.959 | 158.102 | 17.65× | < 5,000 ms | Pass |
| R15 | READ | 10.587 | 200.731 | 18.96× | < 5,000 ms | Pass |
| R16 | READ | 5.498 | 113.787 | 20.70× | < 250 ms | Pass |
| R17 | READ | 11.544 | 200.033 | 17.33× | < 5,000 ms | Pass |
| R18 | READ | 36.881 | 1,271.881 | 34.49× | < 5,000 ms | Pass |
| R19 | READ | 54.516 | 1,631.894 | 29.93× | < 5,000 ms | Pass |
| R20 | READ | 5.495 | 63.181 | 11.50× | < 5,000 ms | Pass |
| R21 | READ | 8.002 | 160.255 | 20.03× | < 5,000 ms | Pass |
| R22 | READ | 6.075 | 8.165 | 1.34× | < 250 ms | Pass |
| R23 | READ | 0.026 | 0.180 | 6.92× | < 5 ms | Pass |
| R24 | READ | 4.626 | 16.766 | 3.62× | < 5,000 ms | Pass |
| R25 | READ | 56.573 | 942.385 | 16.66× | < 5,000 ms | Pass |
| W01 | WRITE | 1.151 | 1.986 | 1.73× | < 5 ms | Pass |
| W02 | WRITE | 1.895 | 0.191 | 0.10× | < 5 ms | Pass |
| W03 | WRITE | 0.466 | 1.116 | 2.39× | < 5 ms | Pass |
| W04 | WRITE | 37.342 | 4,550.976 | 121.87× | < 1,000 ms | **Miss** |
| W05 | WRITE | 1.323 | 0.124 | 0.09× | < 5 ms | Pass |

### 2.1 Target-group summary

| Target group | Queries | Passed | Missed |
|---|---:|---:|---:|
| Real-time / user-facing (< 5 ms) | 13 | 12 | 1 (R03) |
| Interactive (< 250 ms) | 5 | 5 | 0 |
| Reports and analytics (< 5,000 ms) | 11 | 11 | 0 |
| Batch job (< 1,000 ms) | 1 | 0 | 1 (W04) |
| **Total** | **30** | **28** | **2** |

Overall, 28 of 30 queries (93.3%) meet their assigned targets. The two exceptions are R03, the title search, and W04, the bulk expiry update. These misses are explicitly retained in the report rather than represented as passes.

### 2.2 Growth interpretation

- **Approximately stable or lower than seed:** R01, R04–R07, R09, R22, W01–W03 and W05 have growth factors below or close to 1. Some optimized large-dataset averages are lower than the seed measurements; this should be interpreted cautiously because the seed and large benchmarks used different run counts and cache states.
- **Roughly proportional to data volume:** R02, R08, R10, R12–R17, R20, R21, R23 and R25 show growth factors broadly in the approximate 10×–23× range. These queries remain within their assigned thresholds, including the analytics queries whose targets are much more generous than the user-facing targets.
- **Greater-than-20× growth:** R18 (34.49×), R19 (29.93×), and W04 (121.87×) are the clearest high-growth cases. R18 groups listings by seller, title and price; R19 aggregates chat threads and messages before returning active Bengaluru car listings; W04 updates tens of thousands of rows and incurs substantial heap, index and WAL work. R18 and R19 still meet their 5-second analytics target. W04 does not meet its 1-second batch target.

## 3. Large-dataset storage measurements

Storage was measured in `olx_de_dbms_large` after the large dataset had been loaded and the indexes had been created. Values are PostgreSQL relation-size measurements displayed using `pg_size_pretty`, so displayed values are rounded.

### 3.1 Per-table storage

| Table | Table size | Index size | Total size |
|---|---:|---:|---:|
| listings | 718 MB | 319 MB | 1,038 MB |
| chat_messages | 328 MB | 216 MB | 544 MB |
| users | 86 MB | 93 MB | 179 MB |
| chat_threads | 60 MB | 75 MB | 135 MB |
| favourites | 59 MB | 30 MB | 89 MB |
| offers | 30 MB | 8,896 kB | 38 MB |
| seller_ratings | 16 MB | 10,008 kB | 25 MB |
| reports | 12 MB | 3,528 kB | 16 MB |
| boost_packages | 8 kB | 16 kB | 24 kB |
| cities | 8 kB | 16 kB | 24 kB |
| categories | 8 kB | 16 kB | 24 kB |

### 3.2 Aggregate storage

| Measurement | Size |
|---|---:|
| Aggregate table storage in `olx` | 1,308 MB |
| Aggregate index storage in `olx` | 756 MB |
| Aggregate schema storage in `olx` | 2,064 MB |
| Entire `olx_de_dbms_large` database | 2,073 MB |

The aggregate schema size and the database size are different scopes. The database-wide measurement includes database-level overhead beyond the relations included in the `olx` schema query. The rounded per-table totals may not add exactly to the aggregate values.

The largest storage consumers are `listings` (approximately 1,038 MB total) and `chat_messages` (approximately 544 MB total). Together they account for most of the measured schema storage. Indexes occupy approximately 756 MB, so index design has a material storage cost as well as a query-performance benefit.

### 3.3 Seed versus large storage

The seed report recorded approximately 69 MB of table data, 39 MB of indexes and 109 MB total for the `olx` schema. The large schema measurement is approximately 1,308 MB of table data and 756 MB of indexes, or 2,064 MB total. These are rounded PostgreSQL measurements. The schema-level comparison is more appropriate than comparing the seed database-wide size (200 MB, which included the separate `olx_cp4` experiment schema) with the large database-wide size (2,073 MB).

## 4. Large-data query problems and optimizations

The pre-optimization large-data baseline is preserved in `benchmarks/results/large_baseline/`. The final full-workload plans and averages are in `benchmarks/results/large/`. Additional targeted experiments are preserved in their own directories. The comparison below uses the original large-data baseline average and the final full-workload average, not the best isolated experimental run.

| Query | Original large avg (ms) | Final full-workload avg (ms) | Change / explanation |
|---|---:|---:|---|
| R03 | 68.283 | 19.247 | Partial GIN index on active listing titles improved candidate lookup, but heap access and sorting of matching listings remain expensive; target still missed. |
| R04 | 21.010 | 0.393 | Added covering seller-ratings index; final plan uses index-only access for ratings. |
| R05 | 57.584 | 0.070 | Added `(seller_id, listing_id)` index to accelerate seller listing lookup. |
| R06 | 297.699 | 1.368 | Rewrote the buyer/seller `OR` condition into two branches combined with `UNION`; correctness was checked with `EXCEPT ALL` and produced zero missing and zero extra rows. |
| R07 | 60.721 | 0.327 | Added a partial unread-message index and rewrote user-thread selection into buyer and seller branches; correctness comparison produced matching results. |
| R09 | 75.119 | 0.380 | Added a partial composite index on `(category_id, latitude, longitude)` for active listings; final plan uses this index. |
| W02 | 137.274 | 0.191 | Seller/listing index accelerates locating the seller's oldest active listing. |
| W03 | 53.169 | 1.116 | Buyer/thread index accelerates locating the most recent conversation. |
| W05 | 20.435 | 0.124 | Partial pending-offer index supports selecting the highest pending offer and updating pending offers. |
| W04 | 4,177.427 | 4,550.976 | Bulk status update remains expensive due to updating 45,275 rows, heap tuple-version creation, index maintenance and WAL generation. Target missed. |

The final full-workload averages can differ from isolated targeted benchmark averages because the full workload has a different cache and execution history. The final summary CSV is authoritative for target assessment.

### 4.1 Phase 5 indexes retained

The additional index scripts retained for the final implementation are:

- `sql/09_phase5_indexes.sql`
  - `seller_ratings(seller_id) INCLUDE (stars)`
  - `listings(seller_id, listing_id)`
  - `chat_threads(buyer_id, thread_id DESC)`
  - Partial pending-offer index on `offers(listing_id, offer_price DESC, offer_id)` where `status = 'PENDING'`.
- `sql/10_phase5_r07_index.sql`
  - Partial index on `chat_messages(thread_id) INCLUDE (sender_id)` where `is_read = FALSE`.
- `sql/12_phase5_r03_partial_gin.sql`
  - Partial GIN trigram index on `listings(title)` where `status = 'ACTIVE'`.
- `sql/13_phase5_r09_index.sql`
  - Partial B-tree index on `listings(category_id, latitude, longitude)` where `status = 'ACTIVE'`.

The experimental R03 covering price index script (`sql/11_phase5_r03_index.sql`) was removed after the partial GIN approach proved more useful. The original Phase 4 index script, `sql/05_indexes.sql`, remains unchanged.

### 4.2 R03: title search

R03 searches active listings whose title contains `iphone 13`, orders by price and returns the 40 cheapest matches. The original large-data plan used the full trigram index together with an active-listing index and processed a large candidate set before sorting.

A partial GIN trigram index restricted to active listings was created. The final full-workload plan uses `idx_listings_active_title_trgm`, but the final average is 19.247 ms, above the 5 ms target. An isolated three-run experiment averaged 14.504 ms; that isolated figure is not used as the final target result.

The remaining work includes fetching the matching heap tuples and sorting the matching listings by price. The covering-price-index experiment was not retained because its measured result was worse than the partial GIN experiment. R03 remains an acknowledged optimization gap.

### 4.3 R06 and R07: chat queries

R06 originally used a buyer-or-seller condition that led to broad scans and a costly join. It was rewritten as two user-thread branches combined with `UNION`, then joined to listings and the latest message per thread. An `EXCEPT ALL` comparison verified that the rewritten query returned the same rows as the original on the test database: zero missing and zero extra rows.

R07 originally scanned the large messages table to identify unread messages from other users. The rewrite first identifies the user's buyer and seller threads, then joins to unread messages using a partial index. An equivalence comparison confirmed matching results. The final full-workload averages are 1.368 ms for R06 and 0.327 ms for R07, both below 5 ms.

### 4.4 R09: nearby listings

R09 originally scanned many active listings through the expiry index and then applied category and coordinate filters. The plan removed approximately 66,128 rows per worker across three parallel workers to return 131 rows.

The added partial composite index on `(category_id, latitude, longitude)` where `status = 'ACTIVE'` allowed an index scan using all four filter constraints. The query text and Haversine distance calculation were not changed. The final full-workload average is 0.380 ms, below the 5 ms target.

### 4.5 W04: bulk expiry update

W04 changes the status of every active listing whose expiry timestamp is earlier than 1 July 2026. The large-data test updated 45,275 rows per run. The original index scan found the qualifying rows relatively quickly, but the overall update was expensive.

An `EXPLAIN (ANALYZE, BUFFERS, WAL)` test showed approximately 604 MB of WAL in one run, substantial dirty and written buffers, and a much larger total update time than the index scan itself. The listings table has several indexes, including partial indexes whose predicate is `status = 'ACTIVE'`. Changing `status` requires the affected entries to be removed from those partial indexes. The table statistics also showed zero HOT updates in the observed statistics.

Several experiments were performed:
- `VACUUM (ANALYZE)` was run to remove dead tuple versions and refresh statistics. Timings varied; this did not establish a reliable fix for the batch target.
- Session-level `wal_compression = 'pglz'` reduced the WAL bytes in one test but increased that test's execution time. It was not enabled permanently.
- A physical-`ctid` ordering rewrite was tested. Its plan performed a sequential scan of the 2.4-million-row listings table and a hash join, and was slower; it was discarded.
- Index removal or replacement was not adopted because the active partial indexes support important read queries, including R03 and R09.

The final full-workload W04 average is 4,550.976 ms, above the 1,000 ms target. The original large-data baseline average was 4,177.427 ms. This report does not claim W04 was optimized successfully. A production design could consider a separately scheduled/batched expiry process, partition-aware maintenance, or a redesigned index strategy, but each would require correctness testing and a new benchmark before adoption.

## 5. Seed partitioning experiment: HASH by `listing_id`

This isolated experiment was performed on the 120,000-row seed database and is retained as a design study. It is not a large-data benchmark result.

### 5.1 Design and key constraint

An isolated test copy was created as `olx_cp4.listings`, partitioned by `HASH (listing_id)` into eight partitions (`MODULUS 8`, remainders 0 through 7). The original `olx.listings` and its referencing child tables were not changed. The test copy retained the table structure and indexes using `LIKE ... INCLUDING ALL`, restored its outgoing foreign keys to the OLX lookup tables, and copied the seed rows.

This key was chosen because the existing primary key is `PRIMARY KEY (listing_id)` and the existing unique constraint is `UNIQUE (listing_id, seller_id)`. PostgreSQL requires every partition-key column to be included in a partitioned table's primary-key or unique constraint so uniqueness can be enforced across partitions. See the PostgreSQL 18 documentation: [Table Partitioning](https://www.postgresql.org/docs/18/ddl-partitioning.html).

A production migration still needs a dependency and foreign-key migration plan. This experiment deliberately leaves the existing `chat_threads`, `offers`, `favourites`, `reports`, and `seller_ratings` foreign keys pointing to `olx.listings`; it does not swap the original table.

### 5.2 Row distribution

The copy contained 120,000 rows, matching the original table exactly.

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

### 5.3 Partition pruning evidence

For `WHERE listing_id = 100871`, the partitioned plan used an index scan on `listings_h3` only. It did not scan the other seven partitions. The plan showed `Index Cond: (listing_id = 100871)` and execution time of 0.016 ms in the initial single-run comparison. This verifies partition pruning for a predicate on the hash key.

For a representative city/category search (`city_id = 1`, `category_id = 2`, `status = 'ACTIVE'`, ordered by `posted_at DESC`, limit 40), the plan used `Merge Append` with an index scan on each of the eight partitions. Because the predicate did not constrain `listing_id`, no partition could be pruned.

### 5.4 Repeated timing comparison

The same query was run three times against the original and partitioned copies, alternating order. These are microbenchmark measurements of two representative query shapes, not the official 30-query benchmark.

**Direct lookup by `listing_id = 100871`**

| Run | Original (ms) | Partitioned (ms) |
|---|---:|---:|
| 1 | 0.031 | 0.009 |
| 2 | 0.004 | 0.006 |
| 3 | 0.003 | 0.003 |
| **Average** | **0.0127** | **0.0060** |
| **Median** | **0.004** | **0.006** |

The partitioned mean was lower, but the median was slightly higher. With such small timings, first-run effects and cache state are material; this experiment does not prove a stable speedup.

**City/category search without the partition key**

| Run | Original (ms) | Partitioned (ms) |
|---|---:|---:|
| 1 | 0.055 | 0.212 |
| 2 | 0.020 | 0.047 |
| 3 | 0.019 | 0.036 |
| **Average** | **0.0313** | **0.0983** |
| **Median** | **0.020** | **0.047** |

The partitioned query was about 3.14× slower by mean in this small-seed experiment. The original plan used one index scan, while the partitioned plan used `Merge Append` and index scans across all eight partitions. This is evidence that HASH partitioning by `listing_id` does not help city/category browsing when the query has no predicate on the partition key.

### 5.5 Partitioned listing storage

| Design | Table storage | Index storage | Total storage |
|---|---:|---:|---:|
| Original `olx.listings` | 40 MB | 19 MB | 58 MB |
| Eight-partition `olx_cp4.listings` copy | 34 MB | 48 MB | 83 MB |

The partitioned copy used approximately 43% more total storage in this measurement, primarily because its partition-level indexes consumed more space. This is a seed-scale experiment, not a large-data partitioning result.

### 5.6 Partitioning conclusion

The experiment verifies pruning for direct lookups on `listing_id`, but it also shows extra index storage and fan-out across all eight partitions for city/category searches. HASH partitioning by `listing_id` is a validated demonstration and a possible fit for listing-ID-centric access, but it is not established as the best production strategy for the entire workload.

A RANGE strategy on `posted_at` could align better with time-window queries and old-data archival. However, the current primary key and foreign keys depend on `listing_id`; a range-partitioned design would need a carefully designed key and foreign-key change because PostgreSQL's partitioned primary-key/unique constraints must include the partition key. This alternative has not been implemented or benchmarked on the large dataset.

## 6. Architecture proposal for 100× volume

The following is a design proposal, not an implemented or load-tested architecture. A simple 100× extrapolation from the seed row counts would mean roughly 12 million listings, 5 million users, 5.99 million chat threads, 20.95 million chat messages, and 7 million favourites. These are planning estimates, not supplied dataset counts.

### 6.1 Partitioning

Keep partitioning tied to measured predicates. The HASH(`listing_id`) experiment is operationally simple with the current primary key and demonstrated pruning for exact listing-ID lookups, but it did not prune the city/category browsing query and increased measured listing storage from 58 MB to 83 MB on the seed copy.

If retention and date-window access dominate, evaluate RANGE(`posted_at`) partitions (for example, monthly or quarterly) in a separate migration prototype. Before production adoption, redesign the key and every dependent foreign key so uniqueness remains enforceable across partitions. Demonstrate pruning on the real queries and validate inserts, updates, foreign keys, and archival operations.

At 100×, the partition count should be selected from measured large-data query plans, index sizes, memory, maintenance overhead and retention requirements rather than choosing a count based only on row-count arithmetic.

### 6.2 Sharding

A city-based shard key would localize many local browsing queries, but a buyer and seller may live in different cities, and a chat thread references a listing and a buyer. Chat inbox, unread badge, responsiveness, and listing/user history queries could become cross-shard operations. Global search and cross-city analytics would also fan out.

A seller-based shard key would keep a seller's listings together, but buyer favourites, offers, and conversations can involve many sellers, so user-centric history and inbox queries would still span shards.

A listing-based hash shard key is a reasonable first design to evaluate because listing detail, offers, favourites, reports, and the chat thread for a listing can be routed using `listing_id`. Keep a global user directory for identity-to-shard lookup. A buyer's inbox would still need a fan-out across the shards containing their conversations; maintain a per-user conversation index or inbox projection to avoid querying every shard on each request. Cross-shard analytics should run as asynchronous aggregation jobs. These are proposed patterns and need a prototype before implementation.

### 6.3 Read replicas and caching

All writes (W01–W05) must go to the primary. Strongly consistent user-specific operations such as login (R23), My Ads (R05), chat inbox and unread badge (R06/R07), and immediately refreshed ad/detail state should use the primary when read-after-write consistency is required.

Potential replica candidates are read-heavy reports and analytics (R08, R12, R14, R15, R17, R18, R19, R20, R21, R24, R25), provided replica lag is acceptable. Public browsing/search queries (R01, R02, R03, R09) can use a read replica with a short cache TTL if slight staleness is acceptable. Reference data such as cities, categories, and boost-package metadata is a stronger cache candidate than user-specific chat or offer state. Cache invalidation must occur on listing, offer, and moderation changes; do not cache write results or imply strong consistency from an asynchronous replica.

### 6.4 Maintenance, archival, and summaries

Monitor `pg_stat_user_tables` for `n_live_tup`, `n_dead_tup`, `last_autovacuum`, `last_autoanalyze`, and modification counts. Monitor index growth and query plans as the data grows. Keep autovacuum enabled; evaluate table-specific vacuum/analyze scale factors for high-churn `listings`, `chat_messages`, and `offers` only after observing dead tuples and vacuum frequency. Run `ANALYZE` after bulk loading and significant data changes. Avoid setting arbitrary global memory or planner parameters to make benchmark plans look faster.

The W04 experiment showed that large status updates create substantial WAL and index-maintenance work. A production expiry process should evaluate controlled batches, partition-aware retention, or a revised index strategy. Any change must preserve expiry correctness and be benchmarked with the same workload before adoption.

If time-based partitioning is adopted, detach/archive old listing partitions according to retention policy rather than issuing huge row-by-row deletes. Keep archived data queryable through a separate archive schema or storage tier if business and regulatory retention require it. For reports that tolerate delayed freshness, maintain summary tables or materialized views (for example, daily listing counts, category price summaries, and seller response aggregates) and document their refresh schedule and acceptable staleness.

## 7. Conclusion and remaining risks

The faculty-provided large dataset was successfully loaded into a separate PostgreSQL 18.7 database. The 11 tables contain 10,974,400 rows. The large `olx` schema occupies approximately 2,064 MB, comprising approximately 1,308 MB of table data and 756 MB of indexes.

The final three-run benchmark measured all 30 optimized queries. **28 of 30 queries (93.3%) meet their assigned performance targets.** All five interactive queries and all eleven analytics queries pass. Twelve of thirteen real-time/user-facing queries pass. R03 misses its 5 ms target at 19.247 ms, and W04 misses its 1,000 ms target at 4,550.976 ms.

The additional indexes and R06/R07 rewrites materially improved several large-data query plans. The R09 composite partial index reduced a broad active-listing scan to a selective index scan. R03 improved with a partial trigram index but still spends time fetching and sorting matching rows. W04 remains expensive because a bulk status change creates new row versions and requires index and WAL maintenance. These two remaining misses are documented rather than hidden.

The seed HASH partitioning experiment demonstrates pruning for listing-ID lookups but also shows additional index storage and slower city/category browsing when the partition key is absent. It is therefore a design experiment, not a production recommendation for the complete workload.

At 100× volume, the main design risks are high-churn listing updates, large chat/message aggregation, index storage and maintenance, partition-key alignment with real query predicates, and cross-shard user conversations. The proposed architecture uses workload-driven partitioning, listing-oriented sharding with a global user directory and inbox projection, read replicas for lag-tolerant reads, caching for reference/public data, and maintained summaries for analytics. These are proposals requiring further prototype and load testing.

## 8. Finalization checklist

- [x] Create a separate large database and load the faculty-provided `large_data/` files.
- [x] Run `ANALYZE` after loading and indexing.
- [x] Run the optimized workload with three runs per query.
- [x] Save the original large-data baseline separately from the final large-data results.
- [x] Save final raw plans and `benchmarks/results/large/summary.csv`.
- [x] Record all 30 final large averages, growth factors and target outcomes.
- [x] Record large database, table and index storage.
- [x] Document the query optimizations and the two remaining target misses.
- [x] Preserve the seed HASH partitioning experiment and 100× architecture proposal.
- [ ] Verify `.gitignore` excludes `large_data/` and do not commit CSV data or `large_data.zip`.
- [ ] Run `git diff --check`, review the final file list, commit and push the project.
- [ ] Verify the GitHub repository and complete the project tracker/submission.
