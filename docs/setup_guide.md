# Marketing Analytics — Setup Guide

---

## 1. BigQuery Setup

### 1.1 Create (or Select) a Project
1. Go to [console.cloud.google.com](https://console.cloud.google.com).
2. Click the project dropdown → **New Project** (or select an existing one).

### 1.2 Create the Dataset
1. Open **BigQuery** from the left-nav.
2. In the Explorer panel, click the **three-dot menu** next to your project → **Create dataset**.
3. Settings:
   - **Dataset ID**: `marketing_analytics`
   - **Location type**: Multi-region (US) or your preferred region
4. Click **Create Dataset**.

### 1.3 Upload the CSV Files

Repeat for each file:

| CSV File | BigQuery Table Name |
|---|---|
| `data/01_facebook_ads.csv` | `raw_facebook_ads` |
| `data/02_google_ads.csv` | `raw_google_ads` |
| `data/03_tiktok_ads.csv` | `raw_tiktok_ads` |

**Steps:**
1. Click the **three-dot menu** next to `marketing_analytics` → **Create table**.
2. **Source**: Upload → choose the CSV file.
3. **Destination table**: enter the table name from above.
4. **Schema**: check **Auto detect**.
5. **Advanced options**: set **Header rows to skip** to `1`.
6. Click **Create Table**.

**Expected row counts:** FB=110, Google=109, TikTok=109.

---

## 2. Run the SQL Scripts

1. Open `sql/data_quality_checks.sql` in BigQuery → run all checks → verify 0 anomalies.
2. Open `sql/unified_model.sql` → run the CREATE TABLE + verification queries.
3. Open `sql/analytics_views.sql` → run all 3 CREATE VIEW statements.

### Verification Checklist

- [ ] Row count: 110 + 109 + 109 = 328
- [ ] NULL check on core columns: all zeros
- [ ] Campaign count: 4 per platform (12 total)
- [ ] Date range: 2024-01-01 to 2024-01-30

> **Tip**: If `PARSE_DATE` errors, BigQuery may have auto-detected `date` as DATE type. Replace `PARSE_DATE('%Y-%m-%d', date)` with just `date` in the CTEs.

---

## 3. Dashboard

### 3.1 Connect BigQuery to Looker Studio
1. Go to [lookerstudio.google.com](https://lookerstudio.google.com).
2. Click **+ Create** → **Report** → **BigQuery** connector.
3. Navigate to `marketing_analytics` → `unified_ads_performance` → **Add to Report**.

### 3.2 Share the Dashboard
1. Click **Share** in the top right.
2. Change access to **Anyone with the link can view**.
3. Copy the link — this is your deliverable URL.

---

## 4. Deliverables Summary

| Deliverable | Location |
|---|---|
| SQL transformation script | `sql/unified_model.sql` |
| Setup guide | `docs/setup_guide.md` (this file) |
| Looker Studio dashboard | [Link](https://lookerstudio.google.com/reporting/a07e988b-31d2-4105-93e5-56d4fc5b157f/page/TlJ0C) |
