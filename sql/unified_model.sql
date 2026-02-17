-- =============================================================================
-- Unified Ads Performance Model
-- =============================================================================
-- Combines Facebook, Google, and TikTok advertising data into a single
-- standardized table for cross-platform analysis.
--
-- Prerequisites:
--   Dataset: marketing_analytics
--   Raw tables: raw_facebook_ads, raw_google_ads, raw_tiktok_ads
--
-- Output: marketing_analytics.unified_ads_performance
--
-- WHY this approach?
--   Marketing teams need a single source of truth to compare performance
--   across ad platforms. Each platform uses different column names, date
--   formats, and metrics. This script normalizes everything into one
--   table so dashboards and analytics queries don't need platform-specific
--   logic — they just query unified_ads_performance.
-- =============================================================================

CREATE OR REPLACE TABLE `marketing_analytics.unified_ads_performance` AS

-- WHY CTE-per-platform (not one big CASE WHEN)?
--   Each platform has a unique source schema (different column names, different
--   platform-specific metrics). Separate CTEs keep each platform's mapping
--   self-contained and easy to debug. If Google changes a column name
--   tomorrow, only the google CTE needs updating — Facebook and TikTok
--   are untouched. This also makes code reviews easier: each CTE reads
--   like a mini-transformation for one platform.

WITH facebook AS (
  SELECT
    -- WHY PARSE_DATE? Raw CSVs store dates as strings ('2024-01-15').
    -- Explicit parsing ensures BigQuery treats them as DATE type, enabling
    -- date arithmetic, BETWEEN filters, and proper sorting in dashboards.
    PARSE_DATE('%Y-%m-%d', date)                      AS date,
    'Facebook'                                        AS platform,
    campaign_id,
    campaign_name,
    -- WHY alias ad_set_id → ad_group_id? Facebook calls them "ad sets",
    -- Google calls them "ad groups", TikTok calls them "adgroups".
    -- Standardizing to ad_group_id lets downstream queries use one column
    -- name regardless of platform, eliminating CASE WHEN logic everywhere.
    ad_set_id                                         AS ad_group_id,
    ad_set_name                                       AS ad_group_name,
    impressions,
    clicks,
    -- WHY alias spend → cost? Facebook uses "spend", Google/TikTok use "cost".
    -- Standardizing to "cost" as the universal name for ad expenditure.
    spend                                             AS cost,
    conversions,

    -- Facebook-specific columns
    video_views                                       AS fb_video_views,
    engagement_rate                                   AS fb_engagement_rate,
    reach                                             AS fb_reach,
    frequency                                         AS fb_frequency,

    -- WHY typed NULLs for other platforms' columns?
    -- UNION ALL requires identical column counts and compatible types across
    -- all SELECTs. By casting NULLs to the correct type (FLOAT64, INT64),
    -- we preserve the schema so platform-specific analysis still works.
    -- For example, a query filtering on google_quality_score will correctly
    -- return only Google rows (non-NULL), while Facebook/TikTok rows are
    -- naturally excluded.

    -- Google-specific columns (NULL for Facebook)
    CAST(NULL AS FLOAT64)                             AS google_conversion_value,
    CAST(NULL AS FLOAT64)                             AS google_ctr,
    CAST(NULL AS FLOAT64)                             AS google_avg_cpc,
    CAST(NULL AS INT64)                               AS google_quality_score,
    CAST(NULL AS FLOAT64)                             AS google_search_impression_share,

    -- TikTok-specific columns (NULL for Facebook)
    CAST(NULL AS INT64)                               AS tt_video_views,
    CAST(NULL AS INT64)                               AS tt_video_watch_25,
    CAST(NULL AS INT64)                               AS tt_video_watch_50,
    CAST(NULL AS INT64)                               AS tt_video_watch_75,
    CAST(NULL AS INT64)                               AS tt_video_watch_100,
    CAST(NULL AS INT64)                               AS tt_likes,
    CAST(NULL AS INT64)                               AS tt_shares,
    CAST(NULL AS INT64)                               AS tt_comments

  FROM `marketing_analytics.raw_facebook_ads`
),

google AS (
  SELECT
    PARSE_DATE('%Y-%m-%d', date)                      AS date,
    'Google'                                          AS platform,
    campaign_id,
    campaign_name,
    ad_group_id,
    ad_group_name,
    impressions,
    clicks,
    cost,
    conversions,

    -- Facebook-specific columns (NULL for Google)
    CAST(NULL AS INT64)                               AS fb_video_views,
    CAST(NULL AS FLOAT64)                             AS fb_engagement_rate,
    CAST(NULL AS INT64)                               AS fb_reach,
    CAST(NULL AS FLOAT64)                             AS fb_frequency,

    -- Google-specific columns
    conversion_value                                  AS google_conversion_value,
    ctr                                               AS google_ctr,
    avg_cpc                                           AS google_avg_cpc,
    quality_score                                     AS google_quality_score,
    search_impression_share                           AS google_search_impression_share,

    -- TikTok-specific columns (NULL for Google)
    CAST(NULL AS INT64)                               AS tt_video_views,
    CAST(NULL AS INT64)                               AS tt_video_watch_25,
    CAST(NULL AS INT64)                               AS tt_video_watch_50,
    CAST(NULL AS INT64)                               AS tt_video_watch_75,
    CAST(NULL AS INT64)                               AS tt_video_watch_100,
    CAST(NULL AS INT64)                               AS tt_likes,
    CAST(NULL AS INT64)                               AS tt_shares,
    CAST(NULL AS INT64)                               AS tt_comments

  FROM `marketing_analytics.raw_google_ads`
),

tiktok AS (
  SELECT
    PARSE_DATE('%Y-%m-%d', date)                      AS date,
    'TikTok'                                          AS platform,
    campaign_id,
    campaign_name,
    adgroup_id                                        AS ad_group_id,
    adgroup_name                                      AS ad_group_name,
    impressions,
    clicks,
    cost,
    conversions,

    -- Facebook-specific columns (NULL for TikTok)
    CAST(NULL AS INT64)                               AS fb_video_views,
    CAST(NULL AS FLOAT64)                             AS fb_engagement_rate,
    CAST(NULL AS INT64)                               AS fb_reach,
    CAST(NULL AS FLOAT64)                             AS fb_frequency,

    -- Google-specific columns (NULL for TikTok)
    CAST(NULL AS FLOAT64)                             AS google_conversion_value,
    CAST(NULL AS FLOAT64)                             AS google_ctr,
    CAST(NULL AS FLOAT64)                             AS google_avg_cpc,
    CAST(NULL AS INT64)                               AS google_quality_score,
    CAST(NULL AS FLOAT64)                             AS google_search_impression_share,

    -- TikTok-specific columns
    video_views                                       AS tt_video_views,
    video_watch_25                                    AS tt_video_watch_25,
    video_watch_50                                    AS tt_video_watch_50,
    video_watch_75                                    AS tt_video_watch_75,
    video_watch_100                                   AS tt_video_watch_100,
    likes                                             AS tt_likes,
    shares                                            AS tt_shares,
    comments                                          AS tt_comments

  FROM `marketing_analytics.raw_tiktok_ads`
),

-- WHY UNION ALL (not UNION)?
--   UNION removes duplicates by comparing every column in every row — an
--   expensive full-table sort+dedup. UNION ALL simply appends rows, which is:
--   1. Faster — no dedup overhead on 328 rows (and critical at scale).
--   2. Correct — we WANT all rows. A Facebook row and a Google row are never
--      true duplicates (different platform column), and same-platform
--      duplicates were already checked in data_quality_checks.sql.
unioned AS (
  SELECT * FROM facebook
  UNION ALL
  SELECT * FROM google
  UNION ALL
  SELECT * FROM tiktok
)

SELECT
  *,

  -- WHY SAFE_DIVIDE? Standard division (clicks / impressions) throws a
  -- division-by-zero error if impressions = 0 (e.g., a paused ad group
  -- that accrued cost but no impressions). SAFE_DIVIDE returns NULL instead,
  -- which dashboards handle gracefully (blank cell vs. broken query).
  ROUND(SAFE_DIVIDE(clicks, impressions), 6)          AS calc_ctr,
  ROUND(SAFE_DIVIDE(cost, clicks), 2)                 AS calc_cpc,
  ROUND(SAFE_DIVIDE(cost, conversions), 2)            AS calc_cpa,
  ROUND(SAFE_DIVIDE(conversions, clicks), 6)          AS calc_conversion_rate

FROM unioned

-- WHY ORDER BY date, platform, campaign_id?
--   Time-series ordering (date first) is the most natural sort for marketing
--   data — analysts scan day-by-day trends. Platform second groups each day's
--   data by source, and campaign_id third provides deterministic ordering
--   within a platform-day for reproducible results.
ORDER BY date, platform, campaign_id
;


-- =============================================================================
-- Verification Queries (run these after creating the table)
-- =============================================================================

-- 1. Row count by platform (expect ~110 Facebook, ~109 Google, ~109 TikTok)
SELECT
  platform,
  COUNT(*) AS row_count
FROM `marketing_analytics.unified_ads_performance`
GROUP BY platform
ORDER BY platform;

-- 2. Total cost per platform (cross-check against raw tables)
SELECT
  platform,
  ROUND(SUM(cost), 2)          AS total_cost,
  SUM(impressions)             AS total_impressions,
  SUM(clicks)                  AS total_clicks,
  SUM(conversions)             AS total_conversions
FROM `marketing_analytics.unified_ads_performance`
GROUP BY platform
ORDER BY platform;

-- 3. Check for NULLs in core columns
SELECT
  COUNTIF(date IS NULL)          AS null_dates,
  COUNTIF(platform IS NULL)      AS null_platforms,
  COUNTIF(campaign_id IS NULL)   AS null_campaign_ids,
  COUNTIF(impressions IS NULL)   AS null_impressions,
  COUNTIF(clicks IS NULL)        AS null_clicks,
  COUNTIF(cost IS NULL)          AS null_cost,
  COUNTIF(conversions IS NULL)   AS null_conversions
FROM `marketing_analytics.unified_ads_performance`;

-- 4. Campaign count per platform (expect 4 each)
SELECT
  platform,
  COUNT(DISTINCT campaign_id) AS campaign_count
FROM `marketing_analytics.unified_ads_performance`
GROUP BY platform
ORDER BY platform;

-- 5. Date range check
SELECT
  MIN(date) AS earliest_date,
  MAX(date) AS latest_date,
  COUNT(DISTINCT date) AS distinct_days
FROM `marketing_analytics.unified_ads_performance`;
