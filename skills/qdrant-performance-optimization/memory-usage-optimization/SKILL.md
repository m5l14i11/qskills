---
name: qdrant-memory-usage-optimization
description: "Diagnoses and reduces Qdrant memory usage. Use when someone reports 'memory too high', 'RAM keeps growing', 'node crashed', 'out of memory', 'memory leak', or asks 'why is memory usage so high?', 'how to reduce RAM?'. Also use when memory doesn't match calculations, quantization didn't help, or nodes crash during recovery."
---

# What to Do When Qdrant Memory Usage Is Too High

First distinguish data memory from OS page cache. `htop` shows both combined, which is misleading. 80% data = danger. 80% total including cache = often fine.

- Check telemetry to separate data vs cache [Monitoring docs](https://qdrant.tech/documentation/guides/monitoring/)


## Memory Keeps Growing

Use when: RAM grows over time, drops on restart.

- Check telemetry: if data is stable but total climbs, it's cache, not a problem
- If data memory grows with zero traffic, upgrade to latest (known issue before v1.13)
- Check collection count: each adds 12-14 MB overhead [Collections docs](https://qdrant.tech/documentation/concepts/collections/)


## Memory Unexpectedly High

Use when: memory is 2-3x higher than calculations predict.

- Check what's actually in RAM [Storage config](https://qdrant.tech/documentation/concepts/storage/#vector-storage)
- Check HNSW graph location (in RAM unless `on_disk=true`) [HNSW on-disk](https://qdrant.tech/documentation/guides/optimize/#2-high-precision-with-low-memory-usage)
- Check payload indexes (in memory by default) [On-disk indexes](https://qdrant.tech/documentation/concepts/indexing/#on-disk-payload-index)
- Check replication factor (RF=2 = 2x data memory) [Replication](https://qdrant.tech/documentation/guides/distributed_deployment/#replication)
- Check segment count and memmap threshold [Configuring memmap](https://qdrant.tech/documentation/concepts/storage/#configuring-memmap-storage)


## Quantization Didn't Reduce Memory

Use when: enabled quantization but RAM didn't decrease.

- Check optimizer status first (changes may not have taken effect yet) [Optimizer monitoring](https://qdrant.tech/documentation/concepts/optimizer/#optimization-monitoring)
- Check telemetry, not htop (quantization reduces data memory, not cache)
- Verify config: quantized vectors need `always_ram=true`, originals need `on_disk=true` [Scalar quantization setup](https://qdrant.tech/documentation/guides/quantization/#setting-up-scalar-quantization)
- Check for full-text indexes consuming remaining RAM [Full-text index](https://qdrant.tech/documentation/concepts/indexing/#full-text-index)


## Node Crashes with OOM

Use when: node crashes with "cannot allocate memory".

- Consolidate collections using tenant fields [Multitenancy](https://qdrant.tech/documentation/guides/multiple-partitions/)
- Check K8s memory limits (reserve 10-15% headroom)
- Use snapshot-based replication for large shards [Shard transfer](https://qdrant.tech/documentation/guides/distributed_deployment/#shard-transfer-method)
- Upgrade if on older version (v1.11+ improved memory management)


## What NOT to Do

- Dismiss memory growth as "just cache" without checking telemetry
- Set `always_ram=false` on quantization (performance collapse)
- Ignore replication factor (RF=2 = 2x data memory)
- Confuse float16 datatype with quantization (float16 = 2x disk, scalar int8 = 4x memory)
