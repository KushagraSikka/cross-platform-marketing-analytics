# SQL Scripts Documentation

This document explains the 3 SQL scripts in the `sql/` directory, their purpose, key design decisions, and the order in which they should be executed.

---

## Overview

The SQL pipeline follows a 3-step pattern:

```
Raw Tables  →  [1] Validate  →  [2] Transform  →  [3] Analyze
(3 CSVs)       DQ Checks         Unified Table      Analytics Views
```

Each step builds on the previous one. Running them out of order will fail.

---

## Script 1: `sql/data_quality_checks.sql`

**Purpose:** Validate the 3 raw ad-platform tables *before* unification to catch problems at the source.

**When to run:** FIRST — before any transformations. These checks should pass cleanly before proceeding.

### What It Checks (13 checks)

| # | Check | Why It Matters |
|---|-------|---------------|
| 1 | Row counts per table | Confirms full CSV upload (expect FB=110, G=109, TT=109) |
| 2-4 | NULL checks per table | NULLs in core columns break aggregations and CTR/CPA calculations |
| 5 | Duplicate detection | Duplicate rows inflate spend and conversion numbers |
| 6 | Date range validation | All data should fall within January 2024 |
| 7 | Negative value checks | Negative impressions/clicks/spend indicate data corruption |
| 8 | Clicks <= Impressions | A click can't happen without an impression |
| 9 | Conversions <= Clicks | In last-click attribution, conversions require clicks |
| 10 | Spend outliers > $10K | Flags runaway budgets or data entry errors |
| 11 | Google quality_score 1-10 | Platform-defined range — values outside indicate export error |
| 12 | Facebook engagement_rate 0-1 | Ratio metric — values > 1 mean wrong format |
| 13 | Google search_impression_share 0-1 | Percentage metric — must be decimal |

### Key Design Decisions

- **Check raw tables, not the unified table** — Catching issues upstream is cheaper than debugging aggregated downstream metrics.
- **COUNTIF pattern** — Returns a single number per check (0 = clean). Easy to scan results quickly. No need to eyeball hundreds of rows.
- **Platform-specific checks** — Each platform has unique constraints (quality_score is Google-only, engagement_rate is Facebook-only). Generic checks alone would miss these.

### Expected Output
All checks should return 0 for anomaly counts. If any check returns > 0, investigate the raw CSV before proceeding.

---

## Script 2: `sql/unified_model.sql`

**Purpose:** Combine the 3 raw platform tables into a single standardized table (`unified_ads_performance`) with calculated metrics.

**When to run:** SECOND — after all DQ checks pass.

### What It Does

1. **3 platform CTEs** — Each CTE maps its platform's columns to standard names
2. **UNION ALL** — Combines all 3 CTEs into one result set
3. **Calculated metrics** — Adds CTR, CPC, CPA, and conversion rate
4. **Creates table** — Writes the result to `marketing_analytics.unified_ads_performance`

### Column Mapping

| Platform Column | Unified Column | Why |
|----------------|---------------|-----|
| Facebook `ad_set_id` | `ad_group_id` | Standardize naming — all platforms call their mid-level entity differently |
| Facebook `spend` | `cost` | Google and TikTok use `cost`; one name for expenditure |
| TikTok `adgroup_id` | `ad_group_id` | Same standardization |
| All `date` strings | `DATE` type | `PARSE_DATE` ensures type safety for date arithmetic |

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **CTE per platform** (not one big CASE WHEN) | Each platform's mapping is self-contained. If Google changes a column, only the Google CTE changes. |
| **UNION ALL** (not UNION) | Faster — no dedup overhead. Correct — cross-platform rows are never true duplicates. |
| **SAFE_DIVIDE** | Returns NULL instead of error on division by zero (paused ad groups with 0 impressions). |
| **Typed NULLs** (`CAST(NULL AS INT64)`) | UNION ALL requires matching schemas. Typed NULLs preserve column types so platform-specific queries still work. |
| **ORDER BY date, platform, campaign_id** | Time-series first (natural for marketing), platform second (grouping), campaign third (deterministic). |

### Verification

After running, execute the 5 verification queries at the bottom of the script:
1. Row count by platform → 110 + 109 + 109 = 328
2. Cost/impressions/clicks/conversions totals per platform
3. NULL check on core columns → all zeros
4. Campaign count per platform → 4 each (12 total)
5. Date range → 2024-01-01 to 2024-01-31, 31 distinct days

---

## Script 3: `sql/analytics_views.sql`

**Purpose:** Create 3 reusable analytics views on top of the unified table for dashboards and ad-hoc analysis.

**When to run:** THIRD — after `unified_ads_performance` exists.

### View 1: `vw_platform_daily_summary`

| Attribute | Detail |
|-----------|--------|
| **Grain** | One row per (date, platform) |
| **Business question** | How is each platform performing day by day? |
| **Powers** | Daily Trend chart, day-over-day comparisons |
| **Key metrics** | total_spend, total_impressions, total_clicks, total_conversions, daily_ctr, daily_cpc, daily_cpa |

**Why recalculate metrics from SUM?** Averaging pre-calculated CTR across ad groups with different volumes would be misleading (Simpson's paradox). `SUM(clicks) / SUM(impressions)` gives the true daily CTR.

### View 2: `vw_campaign_performance`

| Attribute | Detail |
|-----------|--------|
| **Grain** | One row per (platform, campaign_id) |
| **Business question** | Which campaigns deliver the cheapest conversions? |
| **Powers** | Campaign comparison table, budget reallocation decisions |
| **Key metrics** | All KPIs + `cpa_rank_in_platform` |

**Why rank within platform?** Comparing CPA across platforms is apples-to-oranges (different audiences and intents). Ranking within platform identifies which campaigns to scale vs. pause *on that platform*.

### View 3: `vw_cross_platform_kpis`

| Attribute | Detail |
|-----------|--------|
| **Grain** | One row per platform (3 rows total) |
| **Business question** | How do the 3 platforms compare overall? |
| **Powers** | Executive summary, client-facing reports |
| **Key metrics** | All totals + `pct_of_total_spend` |

**Why % of total spend?** Budget context is critical — a platform with higher CPA might simply be given a harder audience or more budget (diminishing returns).

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Views** (not tables) | Always fresh — re-query base table on every read. No stale-data risk. |
| **3 aggregation levels** | Daily (trends), campaign (optimization), platform (executive summary) — covers all common reporting needs. |
| **SAFE_DIVIDE everywhere** | Consistent NULL handling for zero-denominator edge cases. |

---

## Execution Order

Run these in sequence in the BigQuery console:

```
Step 1 → sql/data_quality_checks.sql     (validate raw data)
           ↓ All checks pass?
Step 2 → sql/unified_model.sql            (create unified table)
           ↓ Verification queries pass?
Step 3 → sql/analytics_views.sql          (create analytics views)
           ↓ Views created successfully?
Step 4 → Open Tableau / HTML dashboard    (visualize)
```

### Expected Outputs After Full Run

| Object | Type | Row Count |
|--------|------|-----------|
| `unified_ads_performance` | Table | 328 rows |
| `vw_platform_daily_summary` | View | ~93 rows (31 days x 3 platforms) |
| `vw_campaign_performance` | View | 12 rows (4 campaigns x 3 platforms) |
| `vw_cross_platform_kpis` | View | 3 rows (1 per platform) |
