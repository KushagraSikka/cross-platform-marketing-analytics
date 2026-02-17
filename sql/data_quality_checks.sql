-- =============================================================================
-- Data Quality Checks — Raw Ad Platform Tables
-- =============================================================================
-- Run these checks BEFORE executing the unified model (unified_model.sql).
-- They validate the 3 raw source tables to catch issues early — before bad
-- data propagates into the unified table and downstream dashboards.
--
-- WHY run DQ checks first?
--   Marketing data comes from 3 different ad platform APIs, each with its own
--   schema, naming conventions, and potential for export errors. Catching
--   problems at the raw layer is cheaper and safer than debugging aggregated
--   metrics after the fact.
--
-- Tables checked:
--   marketing_analytics.raw_facebook_ads   (expected: 110 rows)
--   marketing_analytics.raw_google_ads     (expected: 109 rows)
--   marketing_analytics.raw_tiktok_ads     (expected: 109 rows)
-- =============================================================================


-- =========================================================
-- CHECK 1: Row Counts Per Raw Table
-- =========================================================
-- WHY: Confirms that each CSV was fully loaded into BigQuery.
-- If a row count is off, the CSV upload may have been truncated
-- or a header row was misinterpreted. Expected: FB=110, G=109, TT=109.

SELECT 'Facebook' AS platform, COUNT(*) AS row_count
FROM `marketing_analytics.raw_facebook_ads`
UNION ALL
SELECT 'Google', COUNT(*)
FROM `marketing_analytics.raw_google_ads`
UNION ALL
SELECT 'TikTok', COUNT(*)
FROM `marketing_analytics.raw_tiktok_ads`
ORDER BY platform;


-- =========================================================
-- CHECK 2: NULL Checks — Facebook
-- =========================================================
-- WHY: NULLs in core columns (date, campaign_id, impressions, clicks, spend,
-- conversions) would break joins, aggregations, and calculated metrics like
-- CTR and CPA. Platform-specific NULLs are acceptable only in OTHER
-- platform columns after unification, not in the source table's own fields.

SELECT
  'raw_facebook_ads'                              AS table_name,
  COUNT(*)                                        AS total_rows,
  COUNTIF(date IS NULL)                           AS null_date,
  COUNTIF(campaign_id IS NULL)                    AS null_campaign_id,
  COUNTIF(campaign_name IS NULL)                  AS null_campaign_name,
  COUNTIF(ad_set_id IS NULL)                      AS null_ad_set_id,
  COUNTIF(ad_set_name IS NULL)                    AS null_ad_set_name,
  COUNTIF(impressions IS NULL)                    AS null_impressions,
  COUNTIF(clicks IS NULL)                         AS null_clicks,
  COUNTIF(spend IS NULL)                          AS null_spend,
  COUNTIF(conversions IS NULL)                    AS null_conversions,
  COUNTIF(video_views IS NULL)                    AS null_video_views,
  COUNTIF(engagement_rate IS NULL)                AS null_engagement_rate,
  COUNTIF(reach IS NULL)                          AS null_reach,
  COUNTIF(frequency IS NULL)                      AS null_frequency
FROM `marketing_analytics.raw_facebook_ads`;


-- =========================================================
-- CHECK 3: NULL Checks — Google
-- =========================================================

SELECT
  'raw_google_ads'                                AS table_name,
  COUNT(*)                                        AS total_rows,
  COUNTIF(date IS NULL)                           AS null_date,
  COUNTIF(campaign_id IS NULL)                    AS null_campaign_id,
  COUNTIF(campaign_name IS NULL)                  AS null_campaign_name,
  COUNTIF(ad_group_id IS NULL)                    AS null_ad_group_id,
  COUNTIF(ad_group_name IS NULL)                  AS null_ad_group_name,
  COUNTIF(impressions IS NULL)                    AS null_impressions,
  COUNTIF(clicks IS NULL)                         AS null_clicks,
  COUNTIF(cost IS NULL)                           AS null_cost,
  COUNTIF(conversions IS NULL)                    AS null_conversions,
  COUNTIF(conversion_value IS NULL)               AS null_conversion_value,
  COUNTIF(ctr IS NULL)                            AS null_ctr,
  COUNTIF(avg_cpc IS NULL)                        AS null_avg_cpc,
  COUNTIF(quality_score IS NULL)                  AS null_quality_score,
  COUNTIF(search_impression_share IS NULL)         AS null_search_imp_share
FROM `marketing_analytics.raw_google_ads`;


-- =========================================================
-- CHECK 4: NULL Checks — TikTok
-- =========================================================

SELECT
  'raw_tiktok_ads'                                AS table_name,
  COUNT(*)                                        AS total_rows,
  COUNTIF(date IS NULL)                           AS null_date,
  COUNTIF(campaign_id IS NULL)                    AS null_campaign_id,
  COUNTIF(campaign_name IS NULL)                  AS null_campaign_name,
  COUNTIF(adgroup_id IS NULL)                     AS null_adgroup_id,
  COUNTIF(adgroup_name IS NULL)                   AS null_adgroup_name,
  COUNTIF(impressions IS NULL)                    AS null_impressions,
  COUNTIF(clicks IS NULL)                         AS null_clicks,
  COUNTIF(cost IS NULL)                           AS null_cost,
  COUNTIF(conversions IS NULL)                    AS null_conversions,
  COUNTIF(video_views IS NULL)                    AS null_video_views,
  COUNTIF(video_watch_25 IS NULL)                 AS null_watch_25,
  COUNTIF(video_watch_50 IS NULL)                 AS null_watch_50,
  COUNTIF(video_watch_75 IS NULL)                 AS null_watch_75,
  COUNTIF(video_watch_100 IS NULL)                AS null_watch_100,
  COUNTIF(likes IS NULL)                          AS null_likes,
  COUNTIF(shares IS NULL)                         AS null_shares,
  COUNTIF(comments IS NULL)                       AS null_comments
FROM `marketing_analytics.raw_tiktok_ads`;


-- =========================================================
-- CHECK 5: Duplicate Detection
-- =========================================================
-- WHY: A duplicate (date + campaign_id + ad_group_id) row means the same
-- ad group's performance was counted twice. This inflates spend, impressions,
-- and conversions — making budget decisions unreliable. Duplicates can slip in
-- when a CSV is exported with overlapping date ranges or appended twice.

-- Facebook duplicates
SELECT
  'Facebook' AS platform,
  date, campaign_id, ad_set_id AS ad_group_id,
  COUNT(*) AS occurrences
FROM `marketing_analytics.raw_facebook_ads`
GROUP BY date, campaign_id, ad_set_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;

-- Google duplicates
SELECT
  'Google' AS platform,
  date, campaign_id, ad_group_id,
  COUNT(*) AS occurrences
FROM `marketing_analytics.raw_google_ads`
GROUP BY date, campaign_id, ad_group_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;

-- TikTok duplicates
SELECT
  'TikTok' AS platform,
  date, campaign_id, adgroup_id AS ad_group_id,
  COUNT(*) AS occurrences
FROM `marketing_analytics.raw_tiktok_ads`
GROUP BY date, campaign_id, adgroup_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


-- =========================================================
-- CHECK 6: Date Range Validation
-- =========================================================
-- WHY: The assignment specifies January 2024 data. Any dates outside that
-- window indicate a data export error or mixed-period data that would skew
-- month-over-month analysis and the dashboard's date filters.

SELECT
  'Facebook' AS platform,
  MIN(date) AS earliest_date,
  MAX(date) AS latest_date,
  COUNT(DISTINCT date) AS distinct_days,
  COUNTIF(PARSE_DATE('%Y-%m-%d', date) < '2024-01-01'
       OR PARSE_DATE('%Y-%m-%d', date) > '2024-01-31') AS out_of_range_rows
FROM `marketing_analytics.raw_facebook_ads`
UNION ALL
SELECT
  'Google',
  MIN(date), MAX(date), COUNT(DISTINCT date),
  COUNTIF(PARSE_DATE('%Y-%m-%d', date) < '2024-01-01'
       OR PARSE_DATE('%Y-%m-%d', date) > '2024-01-31')
FROM `marketing_analytics.raw_google_ads`
UNION ALL
SELECT
  'TikTok',
  MIN(date), MAX(date), COUNT(DISTINCT date),
  COUNTIF(PARSE_DATE('%Y-%m-%d', date) < '2024-01-01'
       OR PARSE_DATE('%Y-%m-%d', date) > '2024-01-31')
FROM `marketing_analytics.raw_tiktok_ads`
ORDER BY platform;


-- =========================================================
-- CHECK 7: Negative Value Checks
-- =========================================================
-- WHY: Impressions, clicks, spend, and conversions must be >= 0.
-- Negative values can appear from API corrections (e.g., fraud adjustments)
-- that weren't filtered out during export. Negative spend especially
-- breaks CPC/CPA calculations and misleads budget reporting.

SELECT
  'Facebook' AS platform,
  COUNTIF(impressions < 0) AS neg_impressions,
  COUNTIF(clicks < 0)      AS neg_clicks,
  COUNTIF(spend < 0)       AS neg_spend,
  COUNTIF(conversions < 0) AS neg_conversions
FROM `marketing_analytics.raw_facebook_ads`
UNION ALL
SELECT
  'Google',
  COUNTIF(impressions < 0),
  COUNTIF(clicks < 0),
  COUNTIF(cost < 0),
  COUNTIF(conversions < 0)
FROM `marketing_analytics.raw_google_ads`
UNION ALL
SELECT
  'TikTok',
  COUNTIF(impressions < 0),
  COUNTIF(clicks < 0),
  COUNTIF(cost < 0),
  COUNTIF(conversions < 0)
FROM `marketing_analytics.raw_tiktok_ads`
ORDER BY platform;


-- =========================================================
-- CHECK 8: Logical Consistency — Clicks <= Impressions
-- =========================================================
-- WHY: A click cannot happen without an impression. If clicks > impressions,
-- the data was likely corrupted, or the platform is counting differently
-- (e.g., unique vs. total). Either way, it needs investigation before
-- CTR calculations can be trusted.

SELECT
  'Facebook' AS platform,
  COUNTIF(clicks > impressions) AS clicks_exceed_impressions
FROM `marketing_analytics.raw_facebook_ads`
UNION ALL
SELECT
  'Google',
  COUNTIF(clicks > impressions)
FROM `marketing_analytics.raw_google_ads`
UNION ALL
SELECT
  'TikTok',
  COUNTIF(clicks > impressions)
FROM `marketing_analytics.raw_tiktok_ads`
ORDER BY platform;


-- =========================================================
-- CHECK 9: Logical Consistency — Conversions <= Clicks
-- =========================================================
-- WHY: In standard last-click attribution, a conversion requires a click.
-- Conversions > clicks may indicate view-through attribution is mixed in,
-- or the conversion window spans outside the reporting period.
-- Either way, flag it so the analyst knows the attribution model in use.

SELECT
  'Facebook' AS platform,
  COUNTIF(conversions > clicks) AS conversions_exceed_clicks
FROM `marketing_analytics.raw_facebook_ads`
UNION ALL
SELECT
  'Google',
  COUNTIF(conversions > clicks)
FROM `marketing_analytics.raw_google_ads`
UNION ALL
SELECT
  'TikTok',
  COUNTIF(conversions > clicks)
FROM `marketing_analytics.raw_tiktok_ads`
ORDER BY platform;


-- =========================================================
-- CHECK 10: Spend Sanity — No Single-Day Outliers > $10K
-- =========================================================
-- WHY: A single ad group spending > $10K in one day is unusual for most
-- campaigns at this scale (total monthly spend across all platforms is ~$50K).
-- Outliers like this often indicate a runaway budget, a data entry error,
-- or an incorrect currency. Flagging them early prevents inflated aggregates.

SELECT 'Facebook' AS platform, date, campaign_id, ad_set_id AS ad_group_id, spend AS cost
FROM `marketing_analytics.raw_facebook_ads`
WHERE spend > 10000
UNION ALL
SELECT 'Google', date, campaign_id, ad_group_id, cost
FROM `marketing_analytics.raw_google_ads`
WHERE cost > 10000
UNION ALL
SELECT 'TikTok', date, campaign_id, adgroup_id, cost
FROM `marketing_analytics.raw_tiktok_ads`
WHERE cost > 10000
ORDER BY cost DESC;


-- =========================================================
-- CHECK 11: Google Quality Score — Range 1 to 10
-- =========================================================
-- WHY: Google Ads quality_score is always an integer between 1 and 10.
-- Values outside this range indicate a data export bug or mismatched column.
-- Quality score affects ad rank and CPC, so it must be accurate for
-- any optimization analysis.

SELECT
  COUNT(*) AS total_rows,
  COUNTIF(quality_score < 1 OR quality_score > 10) AS out_of_range,
  MIN(quality_score) AS min_qs,
  MAX(quality_score) AS max_qs,
  ROUND(AVG(quality_score), 2) AS avg_qs
FROM `marketing_analytics.raw_google_ads`;


-- =========================================================
-- CHECK 12: Facebook Engagement Rate — Range 0 to 1
-- =========================================================
-- WHY: Engagement rate is a ratio (engagements / impressions), so it should
-- be between 0 and 1 (i.e., 0% to 100%). Values > 1 suggest the metric
-- was reported as a percentage (e.g., 4.5 instead of 0.045) or that
-- engagements were miscounted.

SELECT
  COUNT(*) AS total_rows,
  COUNTIF(engagement_rate < 0 OR engagement_rate > 1) AS out_of_range,
  MIN(engagement_rate) AS min_er,
  MAX(engagement_rate) AS max_er,
  ROUND(AVG(engagement_rate), 4) AS avg_er
FROM `marketing_analytics.raw_facebook_ads`;


-- =========================================================
-- CHECK 13: Google Search Impression Share — Range 0 to 1
-- =========================================================
-- WHY: Search impression share is a percentage (0 to 1) showing how often
-- your ads appeared vs. total eligible impressions. Values outside this
-- range indicate the data wasn't exported as a decimal.

SELECT
  COUNT(*) AS total_rows,
  COUNTIF(search_impression_share < 0 OR search_impression_share > 1) AS out_of_range,
  MIN(search_impression_share) AS min_sis,
  MAX(search_impression_share) AS max_sis,
  ROUND(AVG(search_impression_share), 4) AS avg_sis
FROM `marketing_analytics.raw_google_ads`;


-- =========================================================
-- SUMMARY
-- =========================================================
-- If all checks above return 0 anomalies / expected row counts:
--   ✅ Data is clean — proceed to unified_model.sql
--
-- If any check flags issues:
--   🔍 Investigate the raw CSV before re-loading
--   📝 Document the finding and any remediation
-- =============================================================================
