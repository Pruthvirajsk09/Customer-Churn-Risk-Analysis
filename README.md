# Customer Churn Risk Scoring Model | SQL · Python · Power BI
**Domain:** Telecom Analytics | **Tools:** MySQL · Python · Power BI · DAX · Pandas · Matplotlib · Seaborn

---

## Business Problem
A telecom company had no early visibility into which customers were at risk of leaving. Retention teams were reacting to churns after they happened rather than identifying at-risk customers before they left. The goal was to build a data-driven risk scoring model that could flag high-risk customers in advance and enable targeted retention action.

---

## Dataset Structure (Multi-Table)
| Table | Rows | Description |
|-------|------|-------------|
| `customers.csv` | 2,500 | Customer demographics — age, gender, city, signup year |
| `subscriptions.csv` | 2,500 | Contract type, tenure, monthly charges, payment method, internet service |
| `churn_outcomes.csv` | 2,500 | Churned Yes/No, customer support calls, churn reason |

**Relationships:**
- `customers[customer_id]` → `subscriptions[customer_id]` (One-to-One)
- `customers[customer_id]` → `churn_outcomes[customer_id]` (One-to-One)

All three tables joined on `customer_id` using SQL INNER JOINs

---

## SQL Analysis
**Key techniques used:**
- `INNER JOIN` across 3 normalized tables to build unified analytical view
- `CTE` (Common Table Expressions) for multi-step risk scoring logic
- `RANK()` window function to rank customers by risk score within each city
- `LAG()` window function for year-over-year churn trend by contract type
- `CASE WHEN` for risk factor scoring across 5 dimensions
- `GROUP BY` and `AGGREGATE` functions for churn rate calculation by segment

**SQL file:** `SQL/Customer Churn Risk Analysis.sql`

---

## Python EDA
**Libraries:** Pandas · NumPy · Matplotlib · Seaborn

**Analyses performed:**
- Data cleaning — null checks, data type validation across merged dataset
- Churn rate distribution by contract type, tenure band, and monthly charges
- Heatmap: Contract Type × Tenure Band churn rate matrix
- Monthly charges distribution comparison — churned vs retained customers
- Customer support call frequency analysis by churn status
- Outlier detection on monthly charges and tenure

**Python file:** `python/P1_Churn_EDA.py`

---

## Key Findings

| Insight | Finding |
|---------|---------|
| Month-to-Month churn rate | **45.4%** vs 9.6% for Two Year contracts (5x higher) |
| 0–12 month tenure customers | Highest churn risk band |
| Critical Risk validation | **65.4%** actual churn vs 2.3% for Low Risk |
| Top churn reason | Price sensitivity |
| Electronic Check payment | **34.1%** churn rate — highest of all payment methods |
| Revenue at risk | Rs.8.2 Lakhs monthly (annualized) |

---

## Risk Scoring Model
Each customer scored across 5 weighted factors:

| Factor | Signal | Risk Weight |
|--------|--------|-------------|
| Contract type | Month-to-Month | 3 |
| Tenure | 0–12 months | 3 |
| Support calls | 5+ calls | 3 |
| Monthly charges | Above Rs.90 | 3 |
| Payment method | Electronic Check | 2 |

**Risk categories:**
- Score ≥ 12 → Critical Risk (65.4% actual churn)
- Score 9–11 → High Risk (38.2% actual churn)
- Score 6–8 → Medium Risk (18.5% actual churn)
- Score < 6 → Low Risk (2.3% actual churn)

---

## Power BI Dashboard (3 Pages)

**Page 1 — Executive Overview**
- KPI cards: Total Customers, Churn Rate %, Critical Risk Count, Revenue at Risk
- Bar chart: Churn rate by contract type
- Donut chart: Churned vs retained split
- Line chart: Churn trend over time (LAG window function)
- Matrix heatmap: Contract × Tenure with conditional formatting (red-amber-green)
- Slicers: City, Gender, Internet Service

**Page 2 — Risk Segmentation**
- Bar chart: Actual churn rate by risk category (validates model accuracy)
- Customer risk tracker table with conditional formatting on risk column
- Drill-through: right-click any segment → filtered customer-level detail

**Page 3 — Churn Drivers**
- Bar chart: Churn rate by tenure band
- Bar chart: Churn rate by payment method
- Bar chart: Churn rate by service type
- Line chart: Monthly charges vs churn rate trend

**DAX measures used:**
```
Churn Rate = DIVIDE(CALCULATE(COUNT(churn_outcomes[customer_id]), churned="Yes"), COUNT(churn_outcomes[customer_id]))

Revenue At Risk = CALCULATE(SUM(subscriptions[monthly_charges]), churned="Yes") * 12

Retention Rate = 1 - [Churn Rate]
```

**Advanced features:**
- Conditional formatting on KPI cards using DAX threshold logic
- Drill-through from overview to customer-level detail page
- Dynamic title using SELECTEDVALUE() DAX function

---

## Skills Demonstrated
`SQL INNER JOINs` · `CTEs` · `Window Functions` · `RANK()` · `LAG()` · `CASE WHEN` · `Python EDA` · `Pandas` · `Seaborn Heatmaps` · `Power BI` · `DAX` · `Data Modeling` · `Conditional Formatting` · `Drill-through` · `KPI Dashboard` · `Risk Scoring` · `Churn Analytics` · `Business Intelligence`

---

## Files in this Repository
```
├── datasets/
│   ├── p1_customers.csv
│   ├── p1_subscriptions.csv
│   └── p1_churn_outcomes.csv
├── sql/
│   └── P1_Churn_SQL_Queries.sql
├── python/
│   └── P1_Churn_EDA.py
├── powerbi/
│   └── Customer_Churn_Dashboard.pbix
├── images/
│   └── dashboard_preview.png
└── README.md
```

---

## How to Run

**SQL:**
1. Create database: `CREATE DATABASE telecom_churn;`
2. Load the 3 CSV files into the respective tables
3. Run queries in `sql/P1_Churn_SQL_Queries.sql` in order

**Python:**
1. Install dependencies: `pip install pandas numpy matplotlib seaborn`
2. Place CSV files in a `datasets/` folder
3. Run: `python python/P1_Churn_EDA.py`

**Power BI:**
1. Open `powerbi/Customer_Churn_Dashboard.pbix` in Power BI Desktop
2. Update data source path to your local CSV location
3. Refresh data
