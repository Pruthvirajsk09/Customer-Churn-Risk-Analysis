

-- ═══════════════════════════════════════════════════════════════
-- PROJECT 1: Customer Churn Analysis | Telecom Domain
-- Tables: customers | subscriptions | churn_outcomes
-- ═══════════════════════════════════════════════════════════════

-- ─── STEP 1: Create Tables & Load Data ──────────────────────────

CREATE DATABASE IF NOT EXISTS telecom_churn;
USE telecom_churn;

CREATE TABLE customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    customer_name VARCHAR(50),
    age INT,
    gender VARCHAR(10),
    city VARCHAR(50),
    signup_year INT
);

CREATE TABLE subscriptions (
    customer_id VARCHAR(10) PRIMARY KEY,
    contract_type VARCHAR(20),
    tenure_months INT,
    internet_service VARCHAR(20),
    phone_service VARCHAR(5),
    streaming_tv VARCHAR(5),
    tech_support VARCHAR(5),
    monthly_charges DECIMAL(8,2),
    total_charges DECIMAL(12,2),
    payment_method VARCHAR(30),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE churn_outcomes (
    customer_id VARCHAR(10) PRIMARY KEY,
    churned VARCHAR(5),
    customer_support_calls INT,
    churn_reason VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- ─── STEP 2: Overall Churn Rate ─────────────────────────────────

SELECT 
    COUNT(*) AS total_customers,
    SUM(CASE WHEN co.churned = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN co.churned = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS churn_rate_pct
FROM customers c
INNER JOIN churn_outcomes co ON c.customer_id = co.customer_id;

-- ─── STEP 3: Churn by Contract Type ─────────────────────────────
-- Key finding: Month-to-Month churns 5x more than Two Year

SELECT 
    s.contract_type,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN co.churned = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN co.churned = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS churn_rate_pct,
    ROUND(AVG(s.monthly_charges), 2) AS avg_monthly_charges
FROM customers c
INNER JOIN subscriptions s ON c.customer_id = s.customer_id
INNER JOIN churn_outcomes co ON c.customer_id = co.customer_id
GROUP BY s.contract_type
ORDER BY churn_rate_pct DESC;

-- ─── STEP 4: Churn by Tenure Band ───────────────────────────────
-- Short tenure customers churn most

SELECT 
    CASE 
        WHEN s.tenure_months <= 12 THEN '0-12 Months'
        WHEN s.tenure_months <= 24 THEN '13-24 Months'
        WHEN s.tenure_months <= 48 THEN '25-48 Months'
        ELSE '48+ Months'
    END AS tenure_band,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN co.churned = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN co.churned = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS churn_rate_pct
FROM subscriptions s
INNER JOIN churn_outcomes co ON s.customer_id = co.customer_id
GROUP BY tenure_band
ORDER BY churn_rate_pct DESC;

-- ─── STEP 5: Churn by Payment Method ────────────────────────────

SELECT 
    s.payment_method,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN co.churned = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN co.churned = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS churn_rate_pct
FROM subscriptions s
INNER JOIN churn_outcomes co ON s.customer_id = co.customer_id
GROUP BY s.payment_method
ORDER BY churn_rate_pct DESC;

-- ─── STEP 6: Churn by City ──────────────────────────────────────

SELECT 
    c.city,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN co.churned = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN co.churned = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS churn_rate_pct
FROM customers c
INNER JOIN churn_outcomes co ON c.customer_id = co.customer_id
GROUP BY c.city
ORDER BY churn_rate_pct DESC;

-- ─── STEP 7: Churn Reason Breakdown ─────────────────────────────

SELECT 
    co.churn_reason,
    COUNT(*) AS churned_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct_of_churned
FROM churn_outcomes co
WHERE co.churned = 'Yes'
GROUP BY co.churn_reason
ORDER BY churned_customers DESC;

-- ─── STEP 8: Revenue at Risk from Churned Customers ─────────────

SELECT 
    ROUND(SUM(s.monthly_charges), 2) AS monthly_revenue_lost,
    ROUND(SUM(s.monthly_charges) * 12, 2) AS annualized_revenue_at_risk
FROM subscriptions s
INNER JOIN churn_outcomes co ON s.customer_id = co.customer_id
WHERE co.churned = 'Yes';

-- ─── STEP 9: Multi-Factor Risk Scoring Model with CTE ───────────
-- This is your key SQL deliverable — joins 3 tables, uses CTE + RANK

WITH customer_risk AS (
    SELECT 
        c.customer_id,
        c.city,
        s.contract_type,
        s.tenure_months,
        s.monthly_charges,
        s.payment_method,
        co.churned,
        co.customer_support_calls,
        -- Risk scoring across 5 factors
        CASE WHEN s.contract_type = 'Month-to-Month' THEN 3
             WHEN s.contract_type = 'One Year' THEN 2
             ELSE 1 END AS contract_risk,
        CASE WHEN s.tenure_months <= 12 THEN 3
             WHEN s.tenure_months <= 24 THEN 2
             ELSE 1 END AS tenure_risk,
        CASE WHEN co.customer_support_calls >= 5 THEN 3
             WHEN co.customer_support_calls >= 3 THEN 2
             ELSE 1 END AS support_risk,
        CASE WHEN s.monthly_charges > 90 THEN 3
             WHEN s.monthly_charges > 60 THEN 2
             ELSE 1 END AS charge_risk,
        CASE WHEN s.payment_method = 'Electronic Check' THEN 2
             ELSE 1 END AS payment_risk
    FROM customers c
    INNER JOIN subscriptions s ON c.customer_id = s.customer_id
    INNER JOIN churn_outcomes co ON c.customer_id = co.customer_id
),
risk_scored AS (
    SELECT *,
        (contract_risk + tenure_risk + support_risk + charge_risk + payment_risk) AS total_risk_score,
        CASE 
            WHEN (contract_risk + tenure_risk + support_risk + charge_risk + payment_risk) >= 12 THEN 'Critical Risk'
            WHEN (contract_risk + tenure_risk + support_risk + charge_risk + payment_risk) >= 9  THEN 'High Risk'
            WHEN (contract_risk + tenure_risk + support_risk + charge_risk + payment_risk) >= 6  THEN 'Medium Risk'
            ELSE 'Low Risk'
        END AS risk_category
    FROM customer_risk
)
SELECT 
    risk_category,
    COUNT(*) AS customer_count,
    SUM(CASE WHEN churned = 'Yes' THEN 1 ELSE 0 END) AS actual_churned,
    ROUND(SUM(CASE WHEN churned = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS actual_churn_rate,
    RANK() OVER (ORDER BY ROUND(SUM(CASE WHEN churned = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) DESC) AS risk_rank
FROM risk_scored
GROUP BY risk_category
ORDER BY actual_churn_rate DESC;

-- ─── STEP 10: Window Function — Month-over-Month Churn Trend ─────

WITH monthly_churn AS (
    SELECT 
        c.signup_year,
        s.contract_type,
        COUNT(*) AS total_customers,
        SUM(CASE WHEN co.churned = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
        ROUND(SUM(CASE WHEN co.churned = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS churn_rate
    FROM customers c
    INNER JOIN subscriptions s ON c.customer_id = s.customer_id
    INNER JOIN churn_outcomes co ON c.customer_id = co.customer_id
    GROUP BY c.signup_year, s.contract_type
)
SELECT *,
    LAG(churn_rate) OVER (PARTITION BY contract_type ORDER BY signup_year) AS prev_year_churn_rate,
    ROUND(churn_rate - LAG(churn_rate) OVER (PARTITION BY contract_type ORDER BY signup_year), 1) AS yoy_change
FROM monthly_churn
ORDER BY contract_type, signup_year;