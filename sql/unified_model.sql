-- Unified Ads Performance Model
-- Combines Facebook, Google, and TikTok data into one standardized table.
-- Output: marketing_analytics.unified_ads_performance

CREATE OR REPLACE TABLE `marketing_analytics.unified_ads_performance` AS

WITH facebook AS (
  SELECT
    PARSE_DATE('%Y-%m-%d', date)                      AS date,
    'Facebook'                                        AS platform,
    campaign_id,
    campaign_name,
    ad_set_id                                         AS ad_group_id,    -- Facebook calls these "ad sets"
    ad_set_name                                       AS ad_group_name,
    impressions,
    clicks,
    spend                                             AS cost,           -- Standardize to "cost"
    conversions,

    -- Facebook-specific
    video_views                                       AS fb_video_views,
    engagement_rate                                   AS fb_engagement_rate,
    reach                                             AS fb_reach,
    frequency                                         AS fb_frequency,

    -- Google-specific (NULL for Facebook)
    CAST(NULL AS FLOAT64)                             AS google_conversion_value,
    CAST(NULL AS FLOAT64)                             AS google_ctr,
    CAST(NULL AS FLOAT64)                             AS google_avg_cpc,
    CAST(NULL AS INT64)                               AS google_quality_score,
    CAST(NULL AS FLOAT64)                             AS google_search_impression_share,

    -- TikTok-specific (NULL for Facebook)
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

    CAST(NULL AS INT64)                               AS fb_video_views,
    CAST(NULL AS FLOAT64)                             AS fb_engagement_rate,
    CAST(NULL AS INT64)                               AS fb_reach,
    CAST(NULL AS FLOAT64)                             AS fb_frequency,

    conversion_value                                  AS google_conversion_value,
    ctr                                               AS google_ctr,
    avg_cpc                                           AS google_avg_cpc,
    quality_score                                     AS google_quality_score,
    search_impression_share                           AS google_search_impression_share,

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

    CAST(NULL AS INT64)                               AS fb_video_views,
    CAST(NULL AS FLOAT64)                             AS fb_engagement_rate,
    CAST(NULL AS INT64)                               AS fb_reach,
    CAST(NULL AS FLOAT64)                             AS fb_frequency,

    CAST(NULL AS FLOAT64)                             AS google_conversion_value,
    CAST(NULL AS FLOAT64)                             AS google_ctr,
    CAST(NULL AS FLOAT64)                             AS google_avg_cpc,
    CAST(NULL AS INT64)                               AS google_quality_score,
    CAST(NULL AS FLOAT64)                             AS google_search_impression_share,

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

unioned AS (
  SELECT * FROM facebook
  UNION ALL
  SELECT * FROM google
  UNION ALL
  SELECT * FROM tiktok
)

SELECT
  *,
  ROUND(SAFE_DIVIDE(clicks, impressions), 6)          AS calc_ctr,
  ROUND(SAFE_DIVIDE(cost, clicks), 2)                 AS calc_cpc,
  ROUND(SAFE_DIVIDE(cost, conversions), 2)            AS calc_cpa,            -- Returns NULL on div-by-zero
  ROUND(SAFE_DIVIDE(conversions, clicks), 6)          AS calc_conversion_rate

FROM unioned
ORDER BY date, platform, campaign_id
;


-- Verification queries (run after creating the table)

-- 1. Row count by platform (expect ~110 Facebook, ~109 Google, ~109 TikTok)
SELECT
  platform,
  COUNT(*) AS row_count
FROM `marketing_analytics.unified_ads_performance`
GROUP BY platform
ORDER BY platform;

-- 2. Total cost per platform
SELECT
  platform,
  ROUND(SUM(cost), 2)          AS total_cost,
  SUM(impressions)             AS total_impressions,
  SUM(clicks)                  AS total_clicks,
  SUM(conversions)             AS total_conversions
FROM `marketing_analytics.unified_ads_performance`
GROUP BY platform
ORDER BY platform;

-- 3. NULL check on core columns
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
