---
name: qdrant-scaling-qps
description: "Guides Qdrant query throughput (QPS) scaling. Use when someone asks 'how to increase QPS', 'need more throughput', 'queries per second too low', 'batch search', 'read replicas', or 'how to handle more concurrent queries'."
allowed-tools:
  - Read
  - Grep
  - Glob
---

# Scaling for Query Throughput (QPS)

Throughput scaling means handling more parallel queries per second. 
This is different from latency - throughput and latency are opposite tuning directions and cannot be optimized simultaneously on the same node.

High throughput favors fewer, larger segments so each query touches less overhead.


## Performance Tuning for Higher RPS

- Use fewer, larger segments (`default_segment_number: 2`) [Maximizing throughput](https://qdrant.tech/documentation/guides/optimize/#maximizing-throughput)
- Enable quantization with `always_ram=true` to reduce disk IO [Quantization](https://qdrant.tech/documentation/guides/quantization/)
- Use batch search API to amortize overhead [Batch search](https://qdrant.tech/documentation/concepts/search/#batch-search-api)

## Minize impact of Update Workloads

- Configure update throughput control (v1.17+) to prevent unoptimized searches degrading reads [Low latency search](https://qdrant.tech/documentation/guides/low-latency-search/)
- Set `optimizer_cpu_budget` to limit indexing CPUs (e.g. `2` on an 8-CPU node reserves 6 for queries)


## Horizontal Scaling for Throughput

If a single node is saturated on CPU after applying the tuning above, scale horizontally with read replicas.

- Read replicas serve queries from replicated shards, distributing read load across nodes
- Each replica adds independent query capacity without re-sharding
- Use `replication_factor: 2+` and route reads to replicas [Distributed deployment](https://qdrant.tech/documentation/guides/distributed_deployment/)

See also [Horizontal Scaling](../scaling-data-volume/horizontal-scaling/SKILL.md) for general horizontal scaling guidance.


## Disk I/O Bottlenecks

If throughput is limited by IOPS rather than CPU:

- Upgrade to provisioned IOPS or local NVMe first
- Use `io_uring` on Linux (kernel 5.11+) [io_uring article](https://qdrant.tech/articles/io_uring/)
- Put sparse vectors and text payloads on disk
- Set `indexing_threshold` high during bulk ingestion to defer indexing
- If still saturated, scale out horizontally (each node adds independent IOPS)


## What NOT to Do

- Do not expect to optimize throughput and latency simultaneously on the same node
- Do not use many small segments for throughput workloads (increases per-query overhead)
- Do not scale horizontally when IOPS-bound without also upgrading disk tier
- Do not run at >90% RAM (OS cache eviction = severe performance degradation)
