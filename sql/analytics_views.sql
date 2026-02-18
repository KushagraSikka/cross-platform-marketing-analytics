-- Analytics Views — Built on unified_ads_performance
-- Run AFTER unified_model.sql has created the base table.
-- Views stay fresh automatically — no need to rebuild when base data updates.


-- VIEW 1: Daily aggregates by platform for trend charts

CREATE OR REPLACE VIEW `marketing_analytics.vw_platform_daily_summary` AS
SELECT
  date,
  platform,
  SUM(cost)                                           AS total_spend,
  SUM(impressions)                                    AS total_impressions,
  SUM(clicks)                                         AS total_clicks,
  SUM(conversions)                                    AS total_conversions,
  ROUND(SAFE_DIVIDE(SUM(clicks), SUM(impressions)), 6)      AS daily_ctr,
  ROUND(SAFE_DIVIDE(SUM(cost), SUM(clicks)), 2)             AS daily_cpc,
  ROUND(SAFE_DIVIDE(SUM(cost), SUM(conversions)), 2)        AS daily_cpa,
  ROUND(SAFE_DIVIDE(SUM(conversions), SUM(clicks)), 6)      AS daily_conversion_rate,
  COUNT(*) AS ad_group_count
FROM `marketing_analytics.unified_ads_performance`
GROUP BY date, platform
ORDER BY date, platform;


-- VIEW 2: Campaign-level KPIs with CPA rank within each platform

CREATE OR REPLACE VIEW `marketing_analytics.vw_campaign_performance` AS
SELECT
  platform,
  campaign_id,
  campaign_name,
  MIN(date)                                                  AS first_active_date,
  MAX(date)                                                  AS last_active_date,
  COUNT(DISTINCT date)                                       AS active_days,
  SUM(cost)                                                  AS total_spend,
  SUM(impressions)                                           AS total_impressions,
  SUM(clicks)                                                AS total_clicks,
  SUM(conversions)                                           AS total_conversions,
  ROUND(SAFE_DIVIDE(SUM(clicks), SUM(impressions)), 6)      AS campaign_ctr,
  ROUND(SAFE_DIVIDE(SUM(cost), SUM(clicks)), 2)             AS campaign_cpc,
  ROUND(SAFE_DIVIDE(SUM(cost), SUM(conversions)), 2)        AS campaign_cpa,
  ROUND(SAFE_DIVIDE(SUM(conversions), SUM(clicks)), 6)      AS campaign_conversion_rate,
  RANK() OVER (
    PARTITION BY platform
    ORDER BY SAFE_DIVIDE(SUM(cost), SUM(conversions)) ASC
  )                                                          AS cpa_rank_in_platform,
  COUNT(DISTINCT ad_group_id)                                AS ad_group_count
FROM `marketing_analytics.unified_ads_performance`
GROUP BY platform, campaign_id, campaign_name
ORDER BY platform, campaign_cpa ASC;


-- VIEW 3: Executive summary — one row per platform with totals and spend share

CREATE OR REPLACE VIEW `marketing_analytics.vw_cross_platform_kpis` AS
WITH platform_totals AS (
  SELECT
    platform,
    ROUND(SUM(cost), 2)                                      AS total_spend,
    SUM(impressions)                                         AS total_impressions,
    SUM(clicks)                                              AS total_clicks,
    SUM(conversions)                                         AS total_conversions,
    ROUND(SAFE_DIVIDE(SUM(clicks), SUM(impressions)), 6)    AS overall_ctr,
    ROUND(SAFE_DIVIDE(SUM(cost), SUM(clicks)), 2)           AS overall_cpc,
    ROUND(SAFE_DIVIDE(SUM(cost), SUM(conversions)), 2)      AS overall_cpa,
    ROUND(SAFE_DIVIDE(SUM(conversions), SUM(clicks)), 6)    AS overall_conversion_rate,
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
  ROUND(SAFE_DIVIDE(pt.total_spend, gt.grand_spend) * 100, 1)  AS pct_of_total_spend
FROM platform_totals pt
CROSS JOIN grand_total gt
ORDER BY pt.total_spend DESC;
