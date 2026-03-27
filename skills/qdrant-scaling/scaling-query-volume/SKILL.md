---
name: qdrant-scaling-query-volume
description: "Guides Qdrant query volume scaling. Use when someone asks 'query returns too many results', 'scroll performance', 'large limit values', 'paginating search results', 'fetching many vectors', or 'high cardinality results'."
allowed-tools:
  - Read
  - Grep
  - Glob
---

# Scaling for Query Volume

By query volume we mean the amount of results that a single query returns.
When queries need to return large result sets, performance degrades because more data must be scored, ranked, and transferred.

Tuning for query volume may require special strategies distinct from throughput or latency optimization.


## Large Result Sets

When queries use high `limit` values (hundreds or thousands of results):

- HNSW graph search becomes less efficient at large limits — it must explore more of the graph
- Network transfer overhead increases with result count
- Memory allocation per query grows with limit size

### Strategies

- Use scroll API for iterating over large result sets instead of high limit values [Scroll points](https://qdrant.tech/documentation/concepts/points/#scroll-points)
- Use pagination with `offset` parameter for user-facing result pages [Search with offset](https://qdrant.tech/documentation/concepts/search/#search-with-offset)
- Apply strict filters to reduce the candidate set before scoring
- Consider using `score_threshold` to cut off low-relevance results early


## GroupBy Queries

When using group-by to aggregate results by a payload field:

- Group-by must overscan to fill groups evenly, increasing internal work
- Set `group_size` and `limit` conservatively [Group-by search](https://qdrant.tech/documentation/concepts/search/#grouping-api)
- Combine with filters to reduce the search space


## What NOT to Do

- Do not use high `limit` values (>100) as a substitute for scroll/pagination
- Do not return full payloads and vectors when only IDs or scores are needed (use `with_payload: false`, `with_vectors: false`)
- Do not expect HNSW to maintain consistent performance at very high limit values
