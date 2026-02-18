-- Data Quality Checks — Raw Ad Platform Tables
-- Run BEFORE unified_model.sql to validate the 3 raw source tables.
-- Tables: raw_facebook_ads (110 rows), raw_google_ads (109), raw_tiktok_ads (109)


-- CHECK 1: Row counts per table (expect FB=110, G=109, TT=109)

SELECT 'Facebook' AS platform, COUNT(*) AS row_count
FROM `marketing_analytics.raw_facebook_ads`
UNION ALL
SELECT 'Google', COUNT(*)
FROM `marketing_analytics.raw_google_ads`
UNION ALL
SELECT 'TikTok', COUNT(*)
FROM `marketing_analytics.raw_tiktok_ads`
ORDER BY platform;


-- CHECK 2: NULL checks — Facebook

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


-- CHECK 3: NULL checks — Google

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


-- CHECK 4: NULL checks — TikTok

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


-- CHECK 5: Duplicate detection (date + campaign_id + ad_group_id)

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


-- CHECK 6: Date range validation (all data should be January 2024)

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


-- CHECK 7: Negative value checks (impressions, clicks, spend, conversions must be >= 0)

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


-- CHECK 8: Clicks should not exceed impressions

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


-- CHECK 9: Conversions should not exceed clicks (last-click attribution)

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


-- CHECK 10: Spend outliers — flag any single-day ad group spend > $10K

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


-- CHECK 11: Google quality_score should be between 1 and 10

SELECT
  COUNT(*) AS total_rows,
  COUNTIF(quality_score < 1 OR quality_score > 10) AS out_of_range,
  MIN(quality_score) AS min_qs,
  MAX(quality_score) AS max_qs,
  ROUND(AVG(quality_score), 2) AS avg_qs
FROM `marketing_analytics.raw_google_ads`;


-- CHECK 12: Facebook engagement_rate should be between 0 and 1

SELECT
  COUNT(*) AS total_rows,
  COUNTIF(engagement_rate < 0 OR engagement_rate > 1) AS out_of_range,
  MIN(engagement_rate) AS min_er,
  MAX(engagement_rate) AS max_er,
  ROUND(AVG(engagement_rate), 4) AS avg_er
FROM `marketing_analytics.raw_facebook_ads`;


-- CHECK 13: Google search_impression_share should be between 0 and 1

SELECT
  COUNT(*) AS total_rows,
  COUNTIF(search_impression_share < 0 OR search_impression_share > 1) AS out_of_range,
  MIN(search_impression_share) AS min_sis,
  MAX(search_impression_share) AS max_sis,
  ROUND(AVG(search_impression_share), 4) AS avg_sis
FROM `marketing_analytics.raw_google_ads`;
