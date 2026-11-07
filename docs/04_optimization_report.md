# CP3 – Database Query Optimization Report

## 1. Overview

This report documents the query optimization work performed for the OLX Buy/Sell database using PostgreSQL.

The optimization work focused on:
- Creating indexes for frequently used query filters, joins, and sorting.
- Rewriting expensive SQL queries.
- Comparing baseline and optimized execution times.
- Examining execution plans using `EXPLAIN (ANALYZE, BUFFERS)`.
- Identifying and correcting a NULL-related query correctness bug.
- Measuring index storage and write-query performance.

**Database:** `olx_de_dbms`  
**Schema:** `olx`  
**PostgreSQL version:** 18.6

## 2. Dataset overview

| Table | Approximate rows |
|---|---:|
| cities | 10 |
| categories | 12 |
| boost_packages | 6 |
| users | 50,000 |
| listings | 120,000 |
| chat_threads | 59,855 |
| chat_messages | 209,529 |
| offers | 19,943 |
| favourites | 70,000 |
| reports | 7,999 |
| seller_ratings | 11,244 |

## 3. Indexes created

Six additional indexes were created in `sql/05_indexes.sql`.

| Index | Columns / type | Purpose |
|---|---|---|
| `idx_listings_active_city_category_posted` | B-tree: city, category, posted date DESC; partial on ACTIVE | R01, R19 and active listing filters |
| `idx_chat_threads_listing` | B-tree: listing_id | Finding conversations belonging to a listing |
| `idx_chat_messages_thread_sent` | B-tree: thread_id, sent_at DESC | Finding messages in a conversation by time |
| `idx_listings_active_expires` | B-tree: expires_at; partial on ACTIVE | Active listing expiry queries |
| `idx_listings_posted_desc` | B-tree: posted_at DESC | Newest-first listing pagination |
| `idx_listings_title_trgm` | GIN with `gin_trgm_ops` | Substring searches on listing titles |

The `pg_trgm` extension was enabled for the title substring-search index.

## 4. Baseline versus optimized query performance

Improvement percentage is calculated as:

`((Baseline time - Optimized time) / Baseline time) × 100`

Positive values indicate faster execution. Negative values indicate slower execution.

| Query | Baseline avg (ms) | Optimized avg (ms) | Improvement |
|---|---:|---:|---:|
| R01 | 9.484 | 0.661 | 93.0% |
| R02 | 6.089 | 0.269 | 95.6% |
| R03 | 20.615 | 2.763 | 86.6% |
| R04 | 0.404 | 0.377 | 6.7% |
| R05 | 1.378 | 1.319 | 4.3% |
| R06 | 70.340 | 15.472 | 78.0% |
| R07 | 5.735 | 5.651 | 1.5% |
| R08 | 5.633 | 4.128 | 26.7% |
| R09 | 6.700 | 3.194 | 52.3% |
| R10 | 5.275 | 0.167 | 96.8% |
| R11 | 1.840 | 1.969 | -7.0% |
| R12 | 35.231 | 34.470 | 2.2% |
| R13 | 15.116 | 10.698 | 29.2%* |
| R14 | 8.980 | 8.959 | 0.2% |
| R15 | 11.709 | 10.587 | 9.6% |
| R16 | 11.800 | 5.498 | 53.4% |
| R17 | 12.053 | 11.544 | 4.2% |
| R18 | 35.138 | 36.881 | -5.0% |
| R19 | 1775.574 | 54.516 | 96.9% |
| R20 | 6.775 | 5.495 | 18.9% |
| R21 | 8.199 | 8.002 | 2.4% |
| R22 | 30.429 | 6.075 | 80.0% |
| R23 | 0.032 | 0.026 | 18.8% |
| R24 | 11.433 | 4.626 | 59.5% |
| R25 | 60.349 | 56.573 | 6.3% |

\*R13 includes a correctness fix, so its original and corrected results are intentionally different.

### Write-query performance

| Query | Baseline avg (ms) | Optimized avg (ms) | Improvement |
|---|---:|---:|---:|
| W01 | 1.185 | 1.151 | 2.9% |
| W02 | 1.688 | 1.895 | -12.3% |
| W03 | 0.980 | 0.466 | 52.4% |
| W04 | 76.275 | 37.342 | 51.0% |
| W05 | 1.735 | 1.323 | 23.7% |

The baseline benchmark used three runs, while the optimized benchmark used five runs as required. Therefore, the comparison should be interpreted with this difference in run counts in mind. Small changes may also reflect execution-time variation.

## 5. Execution-plan analysis

The following five queries were selected for detailed before-and-after plan comparisons.

### R01 – Active listing search

**Baseline plan:**
- Parallel sequential scan on `listings`.
- Approximately 4,424 shared buffer hits for the scan.
- Sorting was required by `posted_at DESC`.

**Optimized plan:**
- Bitmap Index Scan using `idx_listings_active_city_category_posted`.
- Bitmap Heap Scan on `listings`.
- The final top-N sort remains.

Execution time improved from approximately 9.484 ms to 0.661 ms on average, a 93.0% improvement.

### R02 – Filtered listing search

**Baseline plan:**
- Parallel sequential scan on `listings`.
- Approximately 4,424 shared buffer hits for the scan.
- Sorting was required by price.

**Optimized plan:**
- Bitmap Index Scan using `idx_listings_active_city_category_posted`.
- Bitmap Heap Scan on `listings`.
- The final price sort remains.

The heap scan used 119 shared buffer hits, compared with 4,424 for the baseline listing scan. Average execution time improved by 95.6%.

### R10 – Active listings by expiry

**Baseline plan:**
- Parallel sequential scan on `listings`.
- Approximately 4,424 shared buffer hits.
- Sorting by `expires_at`.

**Optimized plan:**
- Index Scan using `idx_listings_active_expires`.
- The index directly supports the active-listing expiry access pattern.

Average execution time improved from 5.275 ms to 0.167 ms, a 96.8% improvement.

### R19 – Listing conversation statistics

**Baseline plan:**
- Correlated subqueries executed for each matching listing.
- Repeated sequential scans of `chat_threads`.
- Repeated scans of `chat_messages` inside the correlated calculation.
- Approximately 473,425 shared buffer hits.

**Optimized plan:**
- Separate aggregate calculations for chat counts and latest message timestamps.
- Hash joins and hash aggregates.
- Bitmap index scan for the active listing filter.
- Approximately 3,144 shared buffer hits.

Average execution time improved from 1,775.574 ms to 54.516 ms, a 96.9% improvement.

This was the most significant query rewrite in this optimization phase.

### R22 – Newest-first listing pagination

**Baseline plan:**
- Sequential scan of all 120,000 listings.
- External merge sort.
- Approximately 6,752 kB of temporary disk space used by the sort.

**Optimized plan:**
- Index Scan using `idx_listings_posted_desc`.
- No external merge sort was required.

Average execution time improved from 30.429 ms to 6.075 ms, an 80.0% improvement.

## 6. Query correctness verification

### R19 – Result equivalence

The original correlated-subquery query and the rewritten aggregate-and-join query were compared using `EXCEPT ALL` in both directions.

| Comparison | Differences |
|---|---:|
| Original minus optimized | 0 |
| Optimized minus original | 0 |

Both counts were zero. This verifies that the R19 rewrite produces exactly the same result rows and values as the original query.

### R13 – NULL-related correctness bug

The original query used:

`NOT IN (SELECT boost_package_id FROM listings)`

The `boost_package_id` column contains NULL values. In SQL, NULL values can cause a `NOT IN` comparison to evaluate to UNKNOWN, preventing expected rows from being returned.

The original query returned zero rows.

It was corrected using `NOT EXISTS`, which checks whether a matching listing exists for each package.

| Method | Rows returned |
|---|---:|
| Original NOT IN | 0 |
| Corrected NOT EXISTS | 2 |

The corrected query identified:

| Package ID | Package name | Price |
|---|---|---:|
| 5 | Urgent tag 7 days | 99.00 |
| 6 | Spotlight 60 days | 1499.00 |

This is an intentional correctness correction rather than a result-preserving rewrite.

## 7. Index storage overhead

The six additional indexes occupy the following storage:

| Index | Storage |
|---|---:|
| `idx_listings_active_city_category_posted` | 328 kB |
| `idx_chat_threads_listing` | 1,248 kB |
| `idx_chat_messages_thread_sent` | 6,472 kB |
| `idx_listings_active_expires` | 240 kB |
| `idx_listings_posted_desc` | 2,656 kB |
| `idx_listings_title_trgm` | 10 MB |

The combined storage is approximately 20.7 MiB.

The title trigram index is the largest index because it supports substring matching across listing titles.

## 8. Write-performance trade-offs

Indexes improve read access but also require maintenance when rows are inserted, updated, or deleted.

In the measured write workload:
- W01 improved by approximately 2.9%.
- W02 became approximately 12.3% slower.
- W03 improved by approximately 52.4%.
- W04 improved by approximately 51.0%.
- W05 improved by approximately 23.7%.

The W02 slowdown demonstrates that optimization does not guarantee every query will become faster. Index maintenance and benchmark variation can affect write performance.

The additional index storage must also be considered when evaluating the overall benefit.

## 9. Queries with limited or negative improvement

Not all queries improved significantly.

- R11 became approximately 7.0% slower.
- R18 became approximately 5.0% slower.
- R14 showed almost no change.
- R07 and R12 showed only small improvements.

Some queries may already be efficient, may process a large portion of a table, or may not benefit substantially from the newly created indexes. Further optimization should be guided by their individual execution plans rather than adding indexes without evidence.

## 10. Conclusion

The CP3 optimization phase introduced six indexes and rewrote the expensive R19 query. The benchmark results show substantial improvements in several read queries, particularly R10, R02, R19, R01, and R22.

The R19 rewrite reduced repeated correlated scans and substantially lowered buffer usage. The R13 correction also addressed a real NULL-related correctness issue.

The six additional indexes occupy approximately 20.7 MiB. While the read improvements are significant, write performance and index storage remain important trade-offs.

Overall, the optimization phase improved several important query access patterns while preserving R19 result equivalence and correcting the R13 NULL-handling bug.

---

**Benchmark evidence:** `benchmarks/results/baseline/` and `benchmarks/results/optimized/`  
**Index definitions:** `sql/05_indexes.sql`  
**Optimized workload:** `sql/06_optimized_queries.sql`  
**Correctness checks:** R19 bidirectional `EXCEPT ALL` comparison and R13 `NOT IN` versus `NOT EXISTS` comparison.

**Measurement note:** Baseline averages are based on three runs; optimized averages are based on five runs. All timings are recorded averages from the benchmark summary files. Individual result-equivalence checks beyond R19 and the R13 correctness correction are not claimed in this report.
