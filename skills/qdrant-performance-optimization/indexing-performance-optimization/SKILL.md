---
name: qdrant-indexing-performance-optimization
description: "Diagnoses and fixes slow Qdrant indexing and data ingestion. Use when someone reports 'uploads are slow', 'indexing takes forever', 'optimizer is stuck', 'HNSW build time too long', or 'data uploaded but search is bad'. Also use when optimizer status shows errors, segments won't merge, or indexing threshold questions arise."
---

# What to Do When Qdrant Indexing Is Too Slow

Qdrant does NOT build HNSW indexes immediately. Small segments use brute-force until they exceed `indexing_threshold_kb` (default: 20 MB). Search during this window is slower by design, not a bug.

- Understand the indexing optimizer [Indexing optimizer](https://qdrant.tech/documentation/concepts/optimizer/#indexing-optimizer)


## Uploads/Ingestion Too Slow

Use when: upload or upsert API calls are slow.

- Use batch upserts (64-256 points per request) [Collections API](https://qdrant.tech/documentation/concepts/collections/)
- Use 2-4 parallel upload streams
- Disable HNSW during bulk load (set `indexing_threshold_kb` very high, restore after) [Collection params](https://qdrant.tech/documentation/concepts/collections/#update-collection-parameters)
- Create payload indexes before HNSW builds (needed for filterable vector index) [Payload index](https://qdrant.tech/documentation/concepts/indexing/#payload-index)
- Setting `m=0` to disable HNSW is legacy, use high `indexing_threshold_kb` instead


## Optimizer Stuck or Taking Too Long

Use when: optimizer running for hours, not finishing.

- Check actual progress via optimizations endpoint (v1.17+) [Optimization monitoring](https://qdrant.tech/documentation/concepts/optimizer/#optimization-monitoring)
- Large merges and HNSW rebuilds legitimately take hours on big datasets
- Merge optimizer processes three smallest segments at a time [Merge optimizer](https://qdrant.tech/documentation/concepts/optimizer/#merge-optimizer)
- Check CPU and disk I/O (HNSW is CPU-bound, merging is I/O-bound, HDD is not viable)
- If `optimizer_status` shows an error, check logs for disk full or corrupted segments


## HNSW Build Time Too High

Use when: HNSW index build dominates total indexing time.

- Reduce `m` (default 16, good for most cases, 32+ rarely needed) [HNSW params](https://qdrant.tech/documentation/concepts/indexing/#vector-index)
- Reduce `ef_construct` (100-200 sufficient) [HNSW config](https://qdrant.tech/documentation/concepts/collections/#indexing-vectors-in-hnsw)
- Increase `max_indexing_threads` (helps but not a silver bullet) [Configuration](https://qdrant.tech/documentation/guides/configuration/)
- Build HNSW in-memory first, move to disk after if needed


## Data Uploaded But Search Quality Is Poor

Use when: data uploaded, search returns bad results.

- Check `indexed_vectors_count` in collection info (if 0, HNSW not built yet)
- Wait for `optimizer_status: ok` [Optimizer monitoring](https://qdrant.tech/documentation/concepts/optimizer/#optimization-monitoring)
- Check if segments are too small to trigger HNSW (merge optimizer needs to combine them first)
- Use `indexed_only=true` in search params to skip unindexed segments
- Check distance metric is correct (Cosine vs Dot) [Collection creation](https://qdrant.tech/documentation/concepts/collections/#create-a-collection)


## What NOT to Do

- Kill Qdrant while optimizer is running (corrupts segments)
- Create payload indexes AFTER HNSW is built (breaks filterable vector index)
- Use `m=0` to disable indexing (legacy, use high `indexing_threshold_kb`)
- Upload one point at a time (per-request overhead dominates)
- Assume search is broken when optimizer is still running
