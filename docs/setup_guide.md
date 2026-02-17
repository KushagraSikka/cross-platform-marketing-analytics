# Marketing Analytics — Setup Guide

End-to-end instructions for loading raw advertising data into BigQuery, running the unified transformation, and building the Looker Studio dashboard.

---

## 1. BigQuery Setup

### 1.1 Create (or Select) a Project
1. Go to [console.cloud.google.com](https://console.cloud.google.com).
2. Click the project dropdown in the top bar → **New Project** (or select an existing one).
3. Note the **Project ID** — you'll need it if running queries via CLI.

### 1.2 Create the Dataset
1. Open **BigQuery** from the left-nav or [console.cloud.google.com/bigquery](https://console.cloud.google.com/bigquery).
2. In the Explorer panel, click the **three-dot menu** next to your project → **Create dataset**.
3. Settings:
   - **Dataset ID**: `marketing_analytics`
   - **Location type**: Multi-region (US) or your preferred region
   - **Default table expiration**: leave blank
4. Click **Create Dataset**.

### 1.3 Upload the CSV Files

Repeat the following for each file:

| CSV File | BigQuery Table Name |
|---|---|
| `data/01_facebook_ads.csv` | `raw_facebook_ads` |
| `data/02_google_ads.csv` | `raw_google_ads` |
| `data/03_tiktok_ads.csv` | `raw_tiktok_ads` |

**Steps for each:**
1. In the Explorer panel, click the **three-dot menu** next to `marketing_analytics` → **Create table**.
2. **Source**: Upload → choose the CSV file.
3. **Destination table**: enter the table name from the table above.
4. **Schema**: check **Auto detect**.
5. **Advanced options**: set **Header rows to skip** to `1`.
6. Click **Create Table**.
7. Once created, click the table → **Preview** tab to verify data looks correct.

**Expected row counts:**
| Table | Data Rows |
|---|---|
| `raw_facebook_ads` | 110 |
| `raw_google_ads` | 109 |
| `raw_tiktok_ads` | 109 |

---

## 2. Run the SQL Transformation

1. In BigQuery, click **+ Compose New Query** (or open the SQL editor).
2. Copy the **entire** contents of `sql/unified_model.sql` and paste it into the editor.
3. **Important**: The script contains multiple statements separated by semicolons. BigQuery runs them sequentially.
4. Click **Run**.
5. The first statement creates the `unified_ads_performance` table. The remaining statements are verification queries.

### Verification Checklist

After running, check the results of the verification queries:

- [ ] **Row count by platform**: Facebook ≈ 110, Google ≈ 109, TikTok ≈ 109 (total ≈ 328)
- [ ] **Total cost per platform**: matches the sum from raw tables
- [ ] **NULL check**: all core columns show 0 NULLs
- [ ] **Campaign count**: 4 campaigns per platform (12 total)
- [ ] **Date range**: 2024-01-01 to 2024-01-30

> **Tip**: If you get an error about `PARSE_DATE`, it means BigQuery auto-detected the `date` column as a DATE type already. In that case, edit the SQL to replace `PARSE_DATE('%Y-%m-%d', date)` with just `date` in all three CTEs.

---

## 3. Looker Studio Dashboard

### 3.1 Connect BigQuery to Looker Studio
1. Go to [lookerstudio.google.com](https://lookerstudio.google.com).
2. Click **+ Create** → **Report**.
3. Under **Google Connectors**, select **BigQuery**.
4. Navigate to: **Your Project** → `marketing_analytics` → `unified_ads_performance`.
5. Click **Add** → **Add to Report**.

### 3.2 Dashboard Layout

Build a single-page dashboard with the following sections, arranged top-to-bottom:

```
┌──────────────────────────────────────────────────────────┐
│  FILTERS: Date Range | Platform | Campaign               │
├──────────────────────────────────────────────────────────┤
│  SCORECARDS                                              │
│  Total Spend | Impressions | Clicks | Conversions        │
│  Overall CTR | Overall CPC | Overall CPA                 │
├────────────────────────────┬─────────────────────────────┤
│  Spend by Platform         │  Daily Performance Trend    │
│  (Donut Chart)             │  (Line Chart)               │
├────────────────────────────┼─────────────────────────────┤
│  Cost Efficiency (CPC/CPA) │  Conversions by Platform    │
│  (Bar Chart)               │  & Campaign (Stacked Bar)   │
├────────────────────────────┴─────────────────────────────┤
│  Campaign Performance Table                              │
│  (All 12 campaigns, sortable)                            │
└──────────────────────────────────────────────────────────┘
```

### 3.3 Filters (Top Bar)

| Filter | Type | Field |
|---|---|---|
| Date Range | Date range control | `date` |
| Platform | Drop-down list | `platform` |
| Campaign | Drop-down list | `campaign_name` |

**How to add:**
1. Click **Add a control** → **Date range control**. Place at top. Set default to Jan 1–30, 2024.
2. Click **Add a control** → **Drop-down list**. Set Control field to `platform`.
3. Click **Add a control** → **Drop-down list**. Set Control field to `campaign_name`.

### 3.4 Scorecards (KPI Row)

Add 7 scorecard charts across the top:

| Scorecard | Metric | Configuration |
|---|---|---|
| Total Spend | `cost` | Aggregation: SUM, Format: Currency |
| Total Impressions | `impressions` | Aggregation: SUM, Format: Number |
| Total Clicks | `clicks` | Aggregation: SUM, Format: Number |
| Total Conversions | `conversions` | Aggregation: SUM, Format: Number |
| Overall CTR | `calc_ctr` | Create calculated field: `SUM(clicks)/SUM(impressions)`, Format: Percent |
| Overall CPC | `calc_cpc` | Create calculated field: `SUM(cost)/SUM(clicks)`, Format: Currency |
| Overall CPA | `calc_cpa` | Create calculated field: `SUM(cost)/SUM(conversions)`, Format: Currency |

> **Note on calculated fields**: For the ratio scorecards (CTR, CPC, CPA), create **Looker Studio calculated fields** rather than using the pre-calculated columns. This ensures correct aggregation when filters are applied:
> - Overall CTR: `SUM(clicks) / SUM(impressions)`
> - Overall CPC: `SUM(cost) / SUM(clicks)`
> - Overall CPA: `SUM(cost) / SUM(conversions)`
>
> To create: **Resource** → **Manage added data sources** → **Edit** → **Add a Field**.

### 3.5 Visualizations

#### Chart 1: Spend by Platform (Donut Chart)
- **Chart type**: Donut chart
- **Dimension**: `platform`
- **Metric**: SUM of `cost`
- **Style**: Show labels with percentage

#### Chart 2: Daily Performance Trend (Line Chart)
- **Chart type**: Time series (line chart)
- **Date dimension**: `date`
- **Breakdown dimension**: `platform`
- **Metric**: SUM of `impressions` (add `clicks` and `conversions` as optional series)
- **Style**: Smooth lines, show data labels

#### Chart 3: Cost Efficiency Comparison (Grouped Bar Chart)
- **Chart type**: Bar chart (grouped/clustered)
- **Dimension**: `platform`
- **Metrics**:
  - Calculated field: `SUM(cost) / SUM(clicks)` (label: "CPC")
  - Calculated field: `SUM(cost) / SUM(conversions)` (label: "CPA")
- **Style**: Grouped bars, different colors for CPC vs CPA

#### Chart 4: Conversions by Platform & Campaign (Stacked Bar Chart)
- **Chart type**: Stacked bar chart
- **Dimension**: `campaign_name`
- **Breakdown dimension**: `platform`
- **Metric**: SUM of `conversions`
- **Sort**: Descending by conversions

#### Chart 5: CTR by Platform (Bar Chart)
- **Chart type**: Bar chart
- **Dimension**: `platform`
- **Metric**: Calculated field `SUM(clicks) / SUM(impressions)`
- **Format**: Percent

#### Chart 6: Campaign Performance Table
- **Chart type**: Table with bars
- **Dimensions**: `platform`, `campaign_name`
- **Metrics**:
  - SUM of `cost`
  - SUM of `impressions`
  - SUM of `clicks`
  - SUM of `conversions`
  - Calculated: CTR (`SUM(clicks)/SUM(impressions)`)
  - Calculated: CPC (`SUM(cost)/SUM(clicks)`)
  - Calculated: CPA (`SUM(cost)/SUM(conversions)`)
- **Enable sorting**: Yes (click column headers)
- **Rows per page**: 12 (to show all campaigns on one page)

### 3.6 Styling Tips
- Use a consistent color scheme for platforms across all charts:
  - Facebook: `#1877F2` (blue)
  - Google: `#34A853` (green)
  - TikTok: `#000000` or `#FF0050` (black or red)
- Add a title at the top: "Cross-Platform Advertising Performance — January 2024"
- Use borders and background colors to visually group related sections

### 3.7 Share the Dashboard
1. Click **Share** in the top right.
2. Change access to **Anyone with the link can view**.
3. Copy the link — this is your deliverable URL.

---

## 4. Deliverables Summary

| Deliverable | Location |
|---|---|
| SQL transformation script | `sql/unified_model.sql` |
| Setup guide | `docs/setup_guide.md` (this file) |
| Looker Studio dashboard | Link generated after Step 3.7 |

---

## Appendix: Column Reference

### Core Columns (all platforms)
| Column | Type | Description |
|---|---|---|
| `date` | DATE | Reporting date |
| `platform` | STRING | Facebook, Google, or TikTok |
| `campaign_id` | STRING | Platform-native campaign ID |
| `campaign_name` | STRING | Campaign name |
| `ad_group_id` | STRING | Ad set/ad group ID |
| `ad_group_name` | STRING | Ad set/ad group name |
| `impressions` | INT64 | Number of ad impressions |
| `clicks` | INT64 | Number of clicks |
| `cost` | FLOAT64 | Spend in USD |
| `conversions` | INT64 | Number of conversions |

### Calculated Columns
| Column | Formula | Description |
|---|---|---|
| `calc_ctr` | clicks / impressions | Click-through rate |
| `calc_cpc` | cost / clicks | Cost per click |
| `calc_cpa` | cost / conversions | Cost per acquisition |
| `calc_conversion_rate` | conversions / clicks | Conversion rate |

### Platform-Specific Columns
| Prefix | Platform | Columns |
|---|---|---|
| `fb_` | Facebook | `video_views`, `engagement_rate`, `reach`, `frequency` |
| `google_` | Google | `conversion_value`, `ctr`, `avg_cpc`, `quality_score`, `search_impression_share` |
| `tt_` | TikTok | `video_views`, `video_watch_25/50/75/100`, `likes`, `shares`, `comments` |
