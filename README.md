# Cross-Platform Marketing Analytics — January 2024

> End-to-end marketing data pipeline: raw ad-platform CSVs &rarr; BigQuery &rarr; SQL transformations &rarr; Looker Studio dashboard

---

## What I Built

A complete analytics pipeline that unifies advertising data from **Facebook**, **Google**, and **TikTok** into a single BigQuery table, validates it with 13 data-quality checks, layers 3 analytics views on top, and visualizes everything in an interactive Looker Studio dashboard.

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
**Looker Studio:** [Cross-Platform Ad Performance — Jan 2024](https://lookerstudio.google.com/reporting/a07e988b-31d2-4105-93e5-56d4fc5b157f/page/TlJ0C)

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
| **BigQuery** | Free tier, serverless, native SQL — matches JD requirement |
| **SQL** | Core data transformation language; listed in JD |
| **Looker Studio** | Native BigQuery integration; interactive filters |
| **Python / Pandas** | Automated CSV unification step |
| **Git / GitHub** | Version control; JD lists Git proficiency |

---

## AI Productivity Note

I used **Claude** (Anthropic) as a productivity tool during this project for documentation structuring/formatting and dashboard layout assistance. All SQL, analysis, and data modeling work is my own.

---

## Challenges & Solutions

| Challenge | Solution |
|-----------|----------|
| **Cross-platform schema mismatch** — each platform uses different column names | CTE-per-platform pattern mapping to standardized names (`ad_group_id`, `cost`) |
| **Division by zero in metrics** — paused ad groups with 0 impressions/clicks | `SAFE_DIVIDE` returns NULL instead of erroring |
| **Platform-specific metrics** — each platform has unique fields (reach, quality_score, etc.) | Typed NULL columns preserve the unified schema while keeping platform data accessible |
| **Dashboard interactivity** | Looker Studio with filters + standalone HTML dashboard with Chart.js for offline use |

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
Open the Looker Studio link above, or
Open dashboard/cross_platform_dashboard.html locally
```

---

## What I'd Build Next

| Enhancement | Why It Matters |
|-------------|---------------|
| **Automated ETL** with Airflow or dbt | Eliminates manual CSV exports; keeps dashboards current |
| **Anomaly Detection** on spend/CTR | Catches runaway budgets before they waste money |
| **Attribution Modeling** | Answers cross-platform conversion influence questions |
| **Budget Optimizer** (ML) | Moves from reporting to prescriptive analytics |
| **dbt Integration** | Industry-standard transformation layer with built-in tests |

---

*Built by Sai Srikar Vechalapu for the Improvado Senior Data Analyst — Marketing assessment.*
