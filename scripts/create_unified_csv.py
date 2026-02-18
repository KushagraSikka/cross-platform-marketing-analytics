"""Merge 3 raw ad-platform CSVs into unified_ads_performance.csv."""

import pandas as pd
import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, "data")

fb = pd.read_csv(os.path.join(DATA_DIR, "01_facebook_ads.csv"))
ggl = pd.read_csv(os.path.join(DATA_DIR, "02_google_ads.csv"))
tt = pd.read_csv(os.path.join(DATA_DIR, "03_tiktok_ads.csv"))

fb_unified = pd.DataFrame({
    "date":                         fb["date"],
    "platform":                     "Facebook",
    "campaign_id":                  fb["campaign_id"],
    "campaign_name":                fb["campaign_name"],
    "ad_group_id":                  fb["ad_set_id"],
    "ad_group_name":                fb["ad_set_name"],
    "impressions":                  fb["impressions"],
    "clicks":                       fb["clicks"],
    "cost":                         fb["spend"],
    "conversions":                  fb["conversions"],
    "fb_video_views":               fb["video_views"],
    "fb_engagement_rate":           fb["engagement_rate"],
    "fb_reach":                     fb["reach"],
    "fb_frequency":                 fb["frequency"],
    "google_conversion_value":      None,
    "google_ctr":                   None,
    "google_avg_cpc":               None,
    "google_quality_score":         None,
    "google_search_impression_share": None,
    "tt_video_views":               None,
    "tt_video_watch_25":            None,
    "tt_video_watch_50":            None,
    "tt_video_watch_75":            None,
    "tt_video_watch_100":           None,
    "tt_likes":                     None,
    "tt_shares":                    None,
    "tt_comments":                  None,
})

ggl_unified = pd.DataFrame({
    "date":                         ggl["date"],
    "platform":                     "Google",
    "campaign_id":                  ggl["campaign_id"],
    "campaign_name":                ggl["campaign_name"],
    "ad_group_id":                  ggl["ad_group_id"],
    "ad_group_name":                ggl["ad_group_name"],
    "impressions":                  ggl["impressions"],
    "clicks":                       ggl["clicks"],
    "cost":                         ggl["cost"],
    "conversions":                  ggl["conversions"],
    "fb_video_views":               None,
    "fb_engagement_rate":           None,
    "fb_reach":                     None,
    "fb_frequency":                 None,
    "google_conversion_value":      ggl["conversion_value"],
    "google_ctr":                   ggl["ctr"],
    "google_avg_cpc":               ggl["avg_cpc"],
    "google_quality_score":         ggl["quality_score"],
    "google_search_impression_share": ggl["search_impression_share"],
    "tt_video_views":               None,
    "tt_video_watch_25":            None,
    "tt_video_watch_50":            None,
    "tt_video_watch_75":            None,
    "tt_video_watch_100":           None,
    "tt_likes":                     None,
    "tt_shares":                    None,
    "tt_comments":                  None,
})

tt_unified = pd.DataFrame({
    "date":                         tt["date"],
    "platform":                     "TikTok",
    "campaign_id":                  tt["campaign_id"],
    "campaign_name":                tt["campaign_name"],
    "ad_group_id":                  tt["adgroup_id"],
    "ad_group_name":                tt["adgroup_name"],
    "impressions":                  tt["impressions"],
    "clicks":                       tt["clicks"],
    "cost":                         tt["cost"],
    "conversions":                  tt["conversions"],
    "fb_video_views":               None,
    "fb_engagement_rate":           None,
    "fb_reach":                     None,
    "fb_frequency":                 None,
    "google_conversion_value":      None,
    "google_ctr":                   None,
    "google_avg_cpc":               None,
    "google_quality_score":         None,
    "google_search_impression_share": None,
    "tt_video_views":               tt["video_views"],
    "tt_video_watch_25":            tt["video_watch_25"],
    "tt_video_watch_50":            tt["video_watch_50"],
    "tt_video_watch_75":            tt["video_watch_75"],
    "tt_video_watch_100":           tt["video_watch_100"],
    "tt_likes":                     tt["likes"],
    "tt_shares":                    tt["shares"],
    "tt_comments":                  tt["comments"],
})

df = pd.concat([fb_unified, ggl_unified, tt_unified], ignore_index=True)

df["calc_ctr"]             = (df["clicks"] / df["impressions"]).round(6)
df["calc_cpc"]             = (df["cost"] / df["clicks"]).round(2)
df["calc_cpa"]             = (df["cost"] / df["conversions"]).round(2)
df["calc_conversion_rate"] = (df["conversions"] / df["clicks"]).round(6)

df = df.sort_values(["date", "platform", "campaign_id"]).reset_index(drop=True)

out_path = os.path.join(DATA_DIR, "unified_ads_performance.csv")
df.to_csv(out_path, index=False)

print(f"Rows: {len(df)}")
print(f"Columns: {list(df.columns)}")
print(f"\nRows by platform:")
print(df["platform"].value_counts().sort_index())
print(f"\nTotal cost: ${df['cost'].sum():,.2f}")
print(f"Total impressions: {df['impressions'].sum():,}")
print(f"Total clicks: {df['clicks'].sum():,}")
print(f"Total conversions: {df['conversions'].sum():,}")
print(f"Distinct campaigns: {df['campaign_id'].nunique()}")
print(f"Date range: {df['date'].min()} to {df['date'].max()}")
print(f"\nSaved to: {out_path}")
