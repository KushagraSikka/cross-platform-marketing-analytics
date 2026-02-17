-- =============================================================================
-- Analytics Views — Built on unified_ads_performance
-- =============================================================================
-- These views sit on top of the unified table and power dashboards + ad-hoc
-- analysis. Run this AFTER unified_model.sql has created the base table.
--
-- WHY views instead of tables?
--   Views are "always fresh" — they re-query the base table on every read.
--   If unified_ads_performance is rebuilt (e.g., after loading new data),
--   these views automatically reflect the update. Tables would need to be
--   rebuilt separately, introducing stale-data risk.
--
-- Prerequisites:
--   marketing_analytics.unified_ads_performance must exist.
-- =============================================================================


-- =========================================================
-- VIEW 1: vw_platform_daily_summary
-- =========================================================
-- WHY: Powers the "Daily Trend" chart in the dashboard and enables quick
-- day-over-day comparison across platforms. Aggregating at the
-- (date × platform) grain reduces 328 rows → ~93 rows, making
-- dashboard queries faster and chart rendering smoother.
--
-- Business question: "How is each platform performing day by day?
-- Are there spend spikes, CTR drops, or conversion surges to investigate?"

CREATE OR REPLACE VIEW `marketing_analytics.vw_platform_daily_summary` AS
SELECT
  date,
  platform,

  -- Volume metrics
  SUM(cost)                                           AS total_spend,
  SUM(impressions)                                    AS total_impressions,
  SUM(clicks)                                         AS total_clicks,
  SUM(conversions)                                    AS total_conversions,

  -- Efficiency metrics (calculated from aggregates, not averaged)
  -- WHY recalculate from SUM? Averaging pre-calculated CTR across ad groups
  -- with different impression volumes would be misleading (Simpson's paradox).
  -- Dividing total clicks by total impressions gives the true daily CTR.
  ROUND(SAFE_DIVIDE(SUM(clicks), SUM(impressions)), 6)      AS daily_ctr,
  ROUND(SAFE_DIVIDE(SUM(cost), SUM(clicks)), 2)             AS daily_cpc,
  ROUND(SAFE_DIVIDE(SUM(cost), SUM(conversions)), 2)        AS daily_cpa,
  ROUND(SAFE_DIVIDE(SUM(conversions), SUM(clicks)), 6)      AS daily_conversion_rate,

  -- Row count (for debugging / sanity checks)
  COUNT(*) AS ad_group_count

FROM `marketing_analytics.unified_ads_performance`
GROUP BY date, platform
ORDER BY date, platform;


-- =========================================================
-- VIEW 2: vw_campaign_performance
-- =========================================================
-- WHY: Rolls up to the campaign level with all KPIs plus a CPA rank
-- within each platform. This lets marketing managers quickly identify
-- their best and worst performing campaigns and reallocate budget
-- from high-CPA campaigns to low-CPA ones.
--
-- Business question: "Which campaigns are delivering the cheapest
-- conversions? Which are burning budget without results?"

CREATE OR REPLACE VIEW `marketing_analytics.vw_campaign_performance` AS
SELECT
  platform,
  campaign_id,
  campaign_name,

  -- Date range this campaign was active
  MIN(date)                                                  AS first_active_date,
  MAX(date)                                                  AS last_active_date,
  COUNT(DISTINCT date)                                       AS active_days,

  -- Volume metrics
  SUM(cost)                                                  AS total_spend,
  SUM(impressions)                                           AS total_impressions,
  SUM(clicks)                                                AS total_clicks,
  SUM(conversions)                                           AS total_conversions,

  -- Efficiency metrics
  ROUND(SAFE_DIVIDE(SUM(clicks), SUM(impressions)), 6)      AS campaign_ctr,
  ROUND(SAFE_DIVIDE(SUM(cost), SUM(clicks)), 2)             AS campaign_cpc,
  ROUND(SAFE_DIVIDE(SUM(cost), SUM(conversions)), 2)        AS campaign_cpa,
  ROUND(SAFE_DIVIDE(SUM(conversions), SUM(clicks)), 6)      AS campaign_conversion_rate,

  -- WHY RANK by CPA within platform? Comparing CPA across platforms is
  -- apples-to-oranges (different audiences, intents, funnel stages).
  -- Ranking within platform tells you which campaigns to scale vs. pause
  -- on THAT platform. Lowest CPA = rank 1 = best performer.
  RANK() OVER (
    PARTITION BY platform
    ORDER BY SAFE_DIVIDE(SUM(cost), SUM(conversions)) ASC
  )                                                          AS cpa_rank_in_platform,

  -- Ad group count (how many ad groups feed this campaign)
  COUNT(DISTINCT ad_group_id)                                AS ad_group_count

FROM `marketing_analytics.unified_ads_performance`
GROUP BY platform, campaign_id, campaign_name
ORDER BY platform, campaign_cpa ASC;


-- =========================================================
-- VIEW 3: vw_cross_platform_kpis
-- =========================================================
-- WHY: Executive summary — one row per platform with totals, averages, and
-- share-of-wallet (% of total spend). This is the view a VP of Marketing
-- looks at to answer "Where is my budget going, and what am I getting back?"
--
-- Business question: "How do Facebook, Google, and TikTok compare overall?
-- Which platform gets the most spend and which delivers the best ROI?"

CREATE OR REPLACE VIEW `marketing_analytics.vw_cross_platform_kpis` AS
WITH platform_totals AS (
  SELECT
    platform,

    -- Volume totals
    ROUND(SUM(cost), 2)                                      AS total_spend,
    SUM(impressions)                                         AS total_impressions,
    SUM(clicks)                                              AS total_clicks,
    SUM(conversions)                                         AS total_conversions,

    -- Efficiency metrics
    ROUND(SAFE_DIVIDE(SUM(clicks), SUM(impressions)), 6)    AS overall_ctr,
    ROUND(SAFE_DIVIDE(SUM(cost), SUM(clicks)), 2)           AS overall_cpc,
    ROUND(SAFE_DIVIDE(SUM(cost), SUM(conversions)), 2)      AS overall_cpa,
    ROUND(SAFE_DIVIDE(SUM(conversions), SUM(clicks)), 6)    AS overall_conversion_rate,

    -- Campaign & date counts
    COUNT(DISTINCT campaign_id)                              AS campaign_count,
    COUNT(DISTINCT date)                                     AS active_days,
    COUNT(*)                                                 AS total_rows

  FROM `marketing_analytics.unified_ads_performance`
  GROUP BY platform
),

grand_total AS (
  SELECT SUM(total_spend) AS grand_spend
  FROM platform_totals
)

SELECT
  pt.*,

  -- WHY % of total spend? Knowing that TikTok gets 40% of budget while
  -- Facebook gets 20% is critical context for interpreting CPA differences.
  -- A platform might have higher CPA simply because it's given harder
  -- audiences or more budget (diminishing returns).
  ROUND(SAFE_DIVIDE(pt.total_spend, gt.grand_spend) * 100, 1)  AS pct_of_total_spend

FROM platform_totals pt
CROSS JOIN grand_total gt
ORDER BY pt.total_spend DESC;
