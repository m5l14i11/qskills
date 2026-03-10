---
name: qdrant-search-quality
description: "Diagnoses and improves Qdrant search relevance. Use when someone reports 'search results are bad', 'wrong results', 'low precision', 'low recall', 'irrelevant matches', 'missing expected results', or asks 'how to improve search quality?', 'which embedding model?', 'should I use hybrid search?', 'should I use reranking?'. Also use when search quality degrades after quantization, model change, or data growth."
---

# What to Do When Qdrant Search Quality Is Bad

First determine whether the problem is the embedding model, Qdrant configuration, or the query strategy. Most quality issues come from the model or data, not from Qdrant itself. Getting this distinction right avoids wasted tuning.


## Identifying the Source of Quality Issues

Use when: results are irrelevant or missing expected matches.

- Test with a known good query/result pair using exact vector search (set `exact=true`) to bypass HNSW approximation [Search API](https://qdrant.tech/documentation/concepts/search/#nearest-neighbors-search)
- If exact search also returns bad results, the problem is the embedding model or data, not Qdrant
- If exact search is good but approximate search is bad, tune HNSW parameters (see below)
- Check if quantization is degrading quality by comparing with and without `quantization` in search params
- Check if filters are too restrictive, causing HNSW to miss good candidates


## Tuning Vector Index Parameters

Use when: approximate search quality is noticeably worse than exact search.

- Increase `hnsw_ef` at query time (higher = better recall, slower search) [Search params](https://qdrant.tech/documentation/guides/optimize/#fine-tuning-search-parameters)
- Increase `ef_construct` when rebuilding index (200+ for high-quality needs) [HNSW config](https://qdrant.tech/documentation/concepts/indexing/#vector-index)
- Increase `m` for better graph connectivity (16 is default, 32 for high recall) [HNSW config](https://qdrant.tech/documentation/concepts/indexing/#vector-index)
- If using quantization, enable oversampling + rescore to recover quality [Search with quantization](https://qdrant.tech/documentation/guides/quantization/#searching-with-quantization)
- Binary quantization requires rescore to be enabled for acceptable quality
- Use ACORN for filtered queries where standard HNSW misses results (v1.16+) [ACORN](https://qdrant.tech/documentation/concepts/search/#acorn-search-algorithm)


## Choosing the Right Embedding Model

Use when: exact search also returns bad results, meaning the vectors themselves are the problem.

- Use the MTEB leaderboard to compare models for your domain and language
- Larger dimensions generally give better quality but cost more RAM and CPU
- Use Matryoshka models to test quality at different dimension sizes before committing [Hybrid queries: multi-stage](https://qdrant.tech/documentation/concepts/hybrid-queries/#multi-stage-queries)
- Domain-specific models (code, legal, medical) outperform general models on specialized data
- Qdrant Cloud inference provides hosted embedding models [Inference docs](https://qdrant.tech/documentation/concepts/inference/)


## When to Use Hybrid Search

Use when: pure vector search misses results that contain obvious keyword matches, or when dealing with domain-specific terminology.

- Combine dense + sparse vectors to get both semantic understanding and keyword matching [Hybrid search](https://qdrant.tech/documentation/concepts/hybrid-queries/#hybrid-search)
- Use `prefetch` to run dense and sparse queries as sub-requests, then fuse results [Prefetch](https://qdrant.tech/documentation/concepts/hybrid-queries/#prefetch)
- Choose fusion method:
  - RRF (Reciprocal Rank Fusion): position-based, good default, supports weighted variants [RRF](https://qdrant.tech/documentation/concepts/hybrid-queries/#reciprocal-rank-fusion-rrf)
  - DBSF (Distribution-Based Score Fusion): score-based normalization, better when score distributions differ [DBSF](https://qdrant.tech/documentation/concepts/hybrid-queries/#distribution-based-score-fusion-dbsf)
- Multi-stage queries: prefetch broad candidates with fast vectors, rescore with accurate ones [Multi-stage](https://qdrant.tech/documentation/concepts/hybrid-queries/#multi-stage-queries)


## When to Use Reranking

Use when: initial retrieval has good recall but poor precision (right documents are in top-100 but not top-10).

- Use cross-encoder rerankers via FastEmbed integration [Rerankers](https://qdrant.tech/documentation/fastembed/fastembed-rerankers/)
- Reranking is a post-retrieval step: retrieve more candidates (oversampling), then rerank to top-k
- ColBERT-style late interaction models can be used as multi-vector rerankers via multi-stage queries [Multi-stage](https://qdrant.tech/documentation/concepts/hybrid-queries/#multi-stage-queries)


## When to Use Relevance Feedback

Use when: you have examples of good/bad results and want to steer search toward similar patterns.

- Recommendation API: provide positive and negative example points to find similar/dissimilar vectors [Recommendation API](https://qdrant.tech/documentation/concepts/explore/#recommendation-api)
  - Average vector strategy: good default for simple positive/negative feedback
  - Best score strategy: better when examples are diverse, supports negative-only queries [Best score](https://qdrant.tech/documentation/concepts/explore/#best-score-strategy)
  - Sum scores strategy: useful for combining multiple relevance signals [Sum scores](https://qdrant.tech/documentation/concepts/explore/#sum-scores-strategy)
- Discovery API: use context pairs (positive-negative) to constrain search regions without a specific target [Discovery](https://qdrant.tech/documentation/concepts/explore/#discovery-api)
- Grouping API: deduplicate results when multiple chunks represent the same document [Grouping](https://qdrant.tech/documentation/concepts/search/#grouping-api)


## What NOT to Do

- Tune Qdrant parameters before verifying the embedding model is the right fit (most quality issues are model issues)
- Use binary quantization without rescore (severe quality loss)
- Set `hnsw_ef` lower than the number of results requested (guaranteed bad recall)
- Skip payload indexes on filtered fields then blame search quality (HNSW can't traverse filtered-out nodes)
- Use a single embedding model for mixed content types (code + natural language + images) without testing quality per type
