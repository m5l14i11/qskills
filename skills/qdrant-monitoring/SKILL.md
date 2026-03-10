---
name: qdrant-monitoring
description: "Guides Qdrant monitoring and observability setup. Use when someone asks 'how to monitor Qdrant', 'what metrics to track', 'is Qdrant healthy', 'optimizer stuck', 'why is memory growing', 'requests are slow', or needs to set up Prometheus, Grafana, or health checks. Also use when debugging production issues that require metric analysis."
---

# Qdrant Monitoring

Qdrant monitoring allows tracking performance and health of your deployment, and identifying issues before they become outages. Available for both self-hosted and cloud deployments, though Cloud provides more advanced features out of the box.


## Prometheus Metrics

Qdrant exposes metrics in Prometheus/OpenMetrics format, scrapable by any compatible monitoring tool.

- Node metrics at `/metrics` endpoint [Monitoring docs](https://qdrant.tech/documentation/guides/monitoring/)
- Cluster metrics at `/sys_metrics` (Qdrant Cloud only)
- Prefix customization via `service.metrics_prefix` config or `QDRANT__SERVICE__METRICS_PREFIX` env var
- Example self-hosted monitoring setup with Prometheus + Grafana [prometheus-monitoring repo](https://github.com/qdrant/prometheus-monitoring)

Key metric categories:
- **Collection metrics**: point counts, vector counts, replica status, pending optimizations
- **API response metrics**: `rest_responses_avg_duration_seconds`, `rest_responses_duration_seconds` (histogram, v1.8+), failure rates. Equivalent `grpc_responses_` prefix for gRPC
- **Process metrics**: memory allocation, threads, file descriptors, page faults
- **Cluster metrics**: Raft consensus state (distributed mode only)
- **Snapshot metrics**: creation and recovery progress


## Liveness and Readiness Probes

For Kubernetes deployments and general health checks:

- `/healthz` for basic status
- `/livez` for liveness probe (is the process alive)
- `/readyz` for readiness probe (is the node ready to serve traffic)
- Read more about health endpoints [Kubernetes health endpoints](https://qdrant.tech/documentation/guides/monitoring/#kubernetes-health-endpoints)


## Optimization Process Observability

Use when: optimizer seems stuck, indexing is taking too long, or you need to verify optimization progress.

- Use `/collections/{collection_name}/optimizations` endpoint (v1.17+) to check optimizer status [Optimization monitoring](https://qdrant.tech/documentation/concepts/optimizer/#optimization-monitoring)
- Query with optional detail flags: `?with=queued,completed,idle_segments`
- Returns: queued optimizations count, active optimizer type, involved segments, progress tracking
- Web UI has an Optimizations tab with timeline view and per-task duration metrics [Web UI](https://qdrant.tech/documentation/concepts/optimizer/#web-ui)
- If `optimizer_status` shows an error in collection info, check logs for disk full or corrupted segments
- Large merges and HNSW rebuilds legitimately take hours on big datasets. Check progress before assuming it's stuck.


## Memory Usage Observability

Use when: memory seems too high, node crashes with OOM, or memory doesn't match expectations.

- Process memory metrics available via `/metrics` (RSS, allocated bytes, page faults)
- Qdrant uses two types of RAM: resident memory (data structures, quantized vectors) and OS page cache (cached disk reads). Page cache filling available RAM is normal. [Memory article](https://qdrant.tech/articles/memory-consumption/)
- If resident memory (RSSAnon) exceeds 80% of total RAM, investigate
- Check `/telemetry` for per-collection breakdown of point counts and vector configurations
- Estimate expected memory: `num_vectors * dimensions * 4 bytes * 1.5` for vectors, plus payload and index overhead [Capacity planning](https://qdrant.tech/documentation/guides/capacity-planning/)
- Common causes of unexpected memory growth: quantized vectors with `always_ram=true`, too many payload indexes, large `max_segment_size` during optimization


## Slow Requests Observability

Use when: queries are slower than expected and you need to identify the cause.

- Track `rest_responses_avg_duration_seconds` and `rest_responses_max_duration_seconds` per endpoint
- Use the histogram metric `rest_responses_duration_seconds` (v1.8+) for percentile analysis in Grafana
- Equivalent gRPC metrics with `grpc_responses_` prefix
- Check optimizer status first. Active optimizations compete for CPU and I/O, degrading search latency.
- Check segment count via collection info. Too many unmerged segments after bulk upload causes slower search.
- Compare filtered vs unfiltered query times. Large gap means missing payload index on the filtered field. [Payload index](https://qdrant.tech/documentation/concepts/indexing/#payload-index)
- Enable JSON log format for structured log analysis: set `logger.format` to `json` in config [Configuration](https://qdrant.tech/documentation/guides/configuration/)


## What NOT to Do

- Scrape `/sys_metrics` on self-hosted (only available on Qdrant Cloud)
- Alert on page cache memory usage (it's supposed to fill available RAM, this is normal OS behavior)
- Ignore optimizer status when debugging slow queries (most common root cause)
- Skip setting up monitoring before going to production (you will regret it)
