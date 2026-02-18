# SQL Scripts Documentation

The 3 SQL scripts in `sql/` follow a sequential pipeline:

```
Raw Tables  →  [1] Validate  →  [2] Transform  →  [3] Analyze
(3 CSVs)       DQ Checks         Unified Table      Analytics Views
```

---

## Script 1: `sql/data_quality_checks.sql`

**Purpose:** Validate the 3 raw ad-platform tables before unification.

**When to run:** FIRST — before any transformations.

### What It Checks (13 checks)

| # | Check |
|---|-------|
| 1 | Row counts per table (expect FB=110, G=109, TT=109) |
| 2-4 | NULL checks per table on all columns |
| 5 | Duplicate detection (date + campaign_id + ad_group_id) |
| 6 | Date range validation (January 2024 only) |
| 7 | Negative value checks on spend/impressions/clicks/conversions |
| 8 | Clicks <= Impressions |
| 9 | Conversions <= Clicks |
| 10 | Spend outliers > $10K per day |
| 11 | Google quality_score in range 1-10 |
| 12 | Facebook engagement_rate in range 0-1 |
| 13 | Google search_impression_share in range 0-1 |

All checks should return 0 anomalies. If any flag issues, investigate the raw CSV before proceeding.

---

## Script 2: `sql/unified_model.sql`

**Purpose:** Combine 3 raw platform tables into `unified_ads_performance` with calculated metrics.

**When to run:** SECOND — after all DQ checks pass.

### What It Does

1. **3 platform CTEs** — each maps platform columns to standard names (`ad_group_id`, `cost`)
2. **UNION ALL** — combines into one result set
3. **Calculated metrics** — adds CTR, CPC, CPA, conversion rate via `SAFE_DIVIDE`
4. **Creates table** — writes to `marketing_analytics.unified_ads_performance`

After running, execute the 5 verification queries at the bottom of the script.

---

## Script 3: `sql/analytics_views.sql`

**Purpose:** Create 3 analytics views on top of the unified table.

**When to run:** THIRD — after `unified_ads_performance` exists.

| View | Grain | Purpose |
|------|-------|---------|
| `vw_platform_daily_summary` | date x platform | Daily trends |
| `vw_campaign_performance` | platform x campaign | Campaign comparison with CPA rank |
| `vw_cross_platform_kpis` | platform | Executive summary with spend share |

---

## Execution Order

```
Step 1 → sql/data_quality_checks.sql     (validate raw data)
Step 2 → sql/unified_model.sql            (create unified table)
Step 3 → sql/analytics_views.sql          (create analytics views)
Step 4 → Open Tableau / HTML dashboard    (visualize)
```

### Expected Outputs

| Object | Type | Rows |
|--------|------|------|
| `unified_ads_performance` | Table | 328 |
| `vw_platform_daily_summary` | View | ~93 |
| `vw_campaign_performance` | View | 12 |
| `vw_cross_platform_kpis` | View | 3 |
