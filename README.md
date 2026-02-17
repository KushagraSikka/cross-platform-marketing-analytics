# Cross-Platform Marketing Analytics — January 2024

> End-to-end marketing data pipeline: raw ad-platform CSVs &rarr; BigQuery &rarr; SQL transformations &rarr; Tableau dashboard

---

## What I Built

A complete analytics pipeline that unifies advertising data from **Facebook**, **Google**, and **TikTok** into a single BigQuery table, validates it with 13 data-quality checks, layers 3 analytics views on top, and visualizes everything in an interactive Tableau dashboard.

The pipeline processes **328 rows** across 3 platforms, 12 campaigns, and 31 days of January 2024 ad performance data.

---

## Key Findings

| # | Insight | Data Point | So What? |
|---|---------|-----------|----------|
| 1 | **Facebook has the best CPA** | $7.64 per conversion | Most cost-efficient platform for conversions — consider shifting budget here |
| 2 | **Google has the highest conversion rate** | 3.07% click-to-conversion | Highest-intent traffic — searches signal purchase intent |
| 3 | **TikTok dominates reach** | 70.9% of all impressions at $0.16 CPC | Best for awareness campaigns; cheapest clicks by far |
| 4 | **Influencer_Collab is the top converter** | 2,683 total conversions | TikTok influencer content drives the most conversions at scale |
| 5 | **Google Generic Search needs optimization** | $24.80 CPA | Broad keywords are expensive — consider tightening match types or adding negatives |

---

## How to Use

### Live Dashboard
**Tableau Public:** [Cross-Platform Ad Performance — Jan 2024](https://public.tableau.com/app/profile/kushagra.sikka/viz/Cross-PlatformAdPerformanceJan2024/)

### HTML Dashboard (offline)
Open `dashboard/cross_platform_dashboard.html` in any browser — no server needed.

### Filters
- **Platform** — Toggle Facebook / Google / TikTok
- **Campaign** — Drill into specific campaigns
- **Date Range** — Focus on specific days

---

## Tech Stack

| Tool | Why I Chose It |
|------|---------------|
| **BigQuery** | Free tier handles this data size; serverless means no infrastructure to manage; native SQL support matches the JD requirement |
| **SQL** | Universal language for data transformation; JD specifically lists SQL expertise as core requirement |
| **Tableau Public** | Free, interactive dashboards with filtering; JD lists Tableau as a required BI tool |
| **Python / Pandas** | Automated the CSV unification step; reproducible data prep |
| **Git / GitHub** | Version control for SQL scripts and documentation; JD lists Git proficiency |

---

## AI Productivity Note

I used **Claude** (Anthropic) as a productivity tool throughout this project:

- **Code generation** — Drafted initial SQL CTEs and data quality check patterns, then reviewed and refined each query
- **Debugging** — Identified schema mismatches across platforms (e.g., Facebook `ad_set_id` vs Google `ad_group_id`)
- **Dashboard automation** — Assisted with Tableau formatting and the standalone HTML dashboard
- **Documentation** — Helped structure this README and SQL documentation for clarity

AI was used as an accelerator, not a replacement for analytical thinking. Every query was reviewed for correctness and business relevance.

---

## Challenges & Solutions

| Challenge | Solution |
|-----------|----------|
| **Cross-platform schema mismatch** — Facebook uses `ad_set_id` + `spend`, Google uses `ad_group_id` + `cost`, TikTok uses `adgroup_id` + `cost` | CTE-per-platform pattern: each CTE maps its platform's columns to standardized names (`ad_group_id`, `cost`), keeping mappings isolated and maintainable |
| **Division by zero in metrics** — Paused ad groups can have 0 impressions or 0 clicks, breaking CTR/CPC/CPA calculations | BigQuery's `SAFE_DIVIDE` returns NULL instead of erroring, and dashboards render NULL as blank rather than crashing |
| **Platform-specific metrics** — Facebook has `reach` and `frequency`, Google has `quality_score`, TikTok has video watch percentiles — can't just drop them | Typed NULL columns (`CAST(NULL AS INT64)`) preserve the unified schema while keeping platform-specific data accessible for deep dives |
| **Dashboard interactivity** — Static charts don't let stakeholders explore the data | Tableau Public with platform/campaign/date filters; plus a standalone HTML dashboard with Chart.js for offline use |

---

## Project Structure

```
Srikar_assignment/
├── README.md                          # This file
├── SQL_SCRIPTS.md                     # SQL documentation & execution guide
├── .gitignore                         # Git exclusions
│
├── data/
│   ├── 01_facebook_ads.csv            # Raw Facebook data (110 rows)
│   ├── 02_google_ads.csv              # Raw Google data (109 rows)
│   ├── 03_tiktok_ads.csv              # Raw TikTok data (109 rows)
│   └── unified_ads_performance.csv    # Merged output (328 rows)
│
├── sql/
│   ├── data_quality_checks.sql        # 13 DQ checks (run FIRST)
│   ├── unified_model.sql              # Unification transform (run SECOND)
│   └── analytics_views.sql            # 3 analytics views (run THIRD)
│
├── scripts/
│   └── create_unified_csv.py          # Python CSV unification script
│
├── dashboard/
│   └── cross_platform_dashboard.html  # Standalone interactive dashboard
│
├── docs/
│   └── setup_guide.md                 # Step-by-step setup instructions
│
└── screenshots/                       # BigQuery DQ check results & dashboard screenshots
```

---

## How to Reproduce

### 1. Set Up BigQuery
```
1. Go to console.cloud.google.com → BigQuery
2. Create dataset: marketing_analytics
3. Upload CSVs as tables:
   - data/01_facebook_ads.csv  → raw_facebook_ads
   - data/02_google_ads.csv    → raw_google_ads
   - data/03_tiktok_ads.csv    → raw_tiktok_ads
```

### 2. Run Data Quality Checks
```
Open sql/data_quality_checks.sql in BigQuery editor
Run each check sequentially
Verify all checks return 0 anomalies
```

### 3. Build Unified Table
```
Open sql/unified_model.sql in BigQuery editor
Run the CREATE TABLE statement
Run the 5 verification queries to confirm
```

### 4. Create Analytics Views
```
Open sql/analytics_views.sql in BigQuery editor
Run all 3 CREATE VIEW statements
```

### 5. Explore the Dashboard
```
Open the Tableau Public link above, or
Open dashboard/cross_platform_dashboard.html locally
```

---

## What I'd Build Next

| Enhancement | Why It Matters |
|-------------|---------------|
| **Automated ETL** — Schedule daily data pulls with Airflow or dbt | Eliminates manual CSV exports; keeps dashboards always current |
| **Anomaly Detection** — Alert on spend spikes or CTR drops > 2 standard deviations | Catches runaway budgets or broken campaigns before they waste money |
| **Attribution Modeling** — Cross-platform conversion attribution | Answers "did the TikTok ad influence the Google search conversion?" |
| **Budget Optimizer** — ML model to recommend optimal budget allocation by platform | Moves from reporting to prescriptive analytics; maximizes ROAS |
| **Audience Overlap Analysis** — Identify shared audiences across platforms | Reduces wasted impressions from showing the same user ads on all 3 platforms |
| **dbt Integration** — Migrate SQL to dbt models with built-in tests and docs | Industry-standard transformation layer; version-controlled tests; auto-generated lineage docs |

---

*Built by Sai Srikar Vechalapu for the Improvado Senior Data Analyst — Marketing assessment.*
