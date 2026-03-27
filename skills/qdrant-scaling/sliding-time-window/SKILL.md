---
name: qdrant-sliding-time-window
description: "Guides sliding time window scaling in Qdrant. Use when someone asks 'only recent data matters', 'how to expire old vectors', 'time-based data rotation', 'delete old data efficiently', 'social media feed search', 'news search', 'log search with retention', or 'how to keep only last N months of data'."
---

# Scaling with a Sliding Time Window

Use when only recent data needs fast search -- social media posts, news articles, support tickets, logs, job listings, real-time feeds. Old data either becomes irrelevant or can tolerate slower access.

Two strategies: **collection rotation** (coarse-grained, zero-downtime, best for clear time boundaries) and **filter-and-delete** (fine-grained, simpler setup, best for continuous cleanup).


## Collection Rotation (Alias Swap)

Use when: data has natural time boundaries (daily, weekly, monthly) and the entire time window can be divided into discrete collections.

- Understand collection aliases [Collection aliases](https://qdrant.tech/documentation/concepts/collections/#collection-aliases)

### How It Works

1. Create one collection per time period (e.g., `posts_2025_01`, `posts_2025_02`, ..., `posts_2025_06`)
2. Point a write alias (e.g., `posts_current`) at the newest collection for ingestion
3. Query across all active collections in parallel from your application, merge results client-side
4. When a new period starts, create the new collection and swap the write alias [Switch collection](https://qdrant.tech/documentation/concepts/collections/#switch-collection)
5. Drop the oldest collection that falls outside the window

### Advantages

- Dropping a collection is instant and reclaims all resources (no fragmentation, no optimizer overhead)
- Each collection is independently sized and optimized
- Old collections can use cheaper storage (mmap, on-disk vectors) while current collection stays in RAM
- No delete-induced segment rebalancing

### Configuration Tips

- Pre-create the next period's collection before the rotation deadline to avoid write disruption
- Use consistent collection configs (vectors, distance, quantization) across all periods for predictable query behavior
- Alias swap is atomic -- no query downtime during rotation [Switch collection](https://qdrant.tech/documentation/concepts/collections/#switch-collection)
- If search must span all active collections, implement fan-out in your application layer and merge results by score


## Filter-and-Delete

Use when: data arrives continuously and rigid time boundaries don't fit, or when you want a single collection without application-level fan-out.

### How It Works

1. Store a `timestamp` payload (integer or datetime) on every point
2. Create a datetime or integer payload index on `timestamp` for fast filtering [Payload index](https://qdrant.tech/documentation/concepts/indexing/#payload-index)
3. At query time, filter to the desired window (e.g., last 6 months) using a `range` condition [Range filter](https://qdrant.tech/documentation/concepts/filtering/#range)
4. Periodically delete expired points using delete-by-filter [Delete points](https://qdrant.tech/documentation/concepts/points/#delete-points)

### Cleanup Scheduling

- Run cleanup during off-peak hours -- bulk deletes trigger segment optimization
- Delete in batches (e.g., 10k-50k points per request) to avoid long optimizer locks
- Monitor optimizer status after large deletes to ensure segments are rebalanced before the next cleanup cycle
- Set `indexing_threshold` high during bulk deletes if you want to defer re-indexing

### Trade-offs vs Collection Rotation

- Simpler architecture (single collection, no fan-out)
- But deletes are not free: they mark points as tombstoned, and the optimizer must compact segments later
- Large accumulated deletes can temporarily degrade search performance until optimization completes
- Does not reclaim disk instantly (compaction is asynchronous)


## Hybrid: Rotation + Hot/Cold Tiers

Use when: recent data needs fast in-RAM search, but older data should remain searchable at lower performance.

1. Keep the current period's collection fully in RAM (quantization with `always_ram: true`)
2. Move older (but still in-window) collections to mmap with on-disk vectors [Quantization](https://qdrant.tech/documentation/guides/quantization/)
3. Drop collections that fall entirely outside the retention window
4. Query hot and cold collections in parallel, merge results

This gives a cost-efficient gradient: fast for recent, cheap for older, gone when expired.


## What NOT to Do

- Do not use filter-and-delete as the sole strategy for high-volume time-series with millions of daily deletes (optimizer will not keep up -- use collection rotation instead)
- Do not forget to index the timestamp field (range filters without an index cause full scans)
- Do not query across many small collections if latency matters (fan-out overhead adds up -- prefer fewer, larger time periods)
- Do not drop a collection before verifying that its time period is fully outside the retention window
- Do not skip pre-creating the next period's collection (write failures during rotation are hard to recover from)
