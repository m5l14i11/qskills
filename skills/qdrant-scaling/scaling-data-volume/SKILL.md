# Scaling Data Volume

This document coverts scenarions of scaling for data volume,
 where the total size of the dataset exceeds the capacity of a single node.

## Tenant Scaling

If the use-case is multi-tenant, meaning that the single user only have access to a subset of the data, 
and we never need to query across all the data, then we can use multi-tenancy patterns to scale.

The recommended way is to use multi-tenant workloads with payload partitioning, per-tenant indexes, and tiered multitenancy.

Learn more [Tenant Scaling](tenant-scaling/SKILL.md)

## Sliding Time Window

Some use-cases are based on a sliding time window, where only the most recent data is relevant.
For example an index for social media posts, where only the last 6 months of data require fast search.

Learn more [Sliding Time Window](sliding-time-window/SKILL.md)

## Global Search

Most general use-cases require global search across all data.
In this situations, we might need to fallback to vertical scaling,
and then horizontal scaling when we reach the limits of vertical scaling.


### Vertical Scaling

ToDo

### Horizontal Scaling

ToDo
