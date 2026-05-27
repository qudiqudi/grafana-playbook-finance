-- Seed ~18 months of plausible finance data, relative to CURRENT_DATE so the
-- dashboards always show "recent" activity no matter when you boot the stack.
-- All figures are randomized within sensible ranges; revenue trends upward
-- faster than expenses so the margin story improves over time.

-- 120 customers spread across regions, segments, and the last ~2 years.
INSERT INTO customers (name, region, segment, created_at)
SELECT
    'Customer ' || g,
    (ARRAY['North America','EMEA','APAC','LATAM'])[1 + (random()*3)::int],
    (ARRAY['Enterprise','Mid-Market','SMB'])[1 + (random()*2)::int],
    (CURRENT_DATE - ((random()*720)::int) * interval '1 day')::date
FROM generate_series(1, 120) g;

-- Opening cash position, set 18 months back so the running balance has a base.
INSERT INTO cash_opening (as_of, balance)
VALUES ((date_trunc('month', CURRENT_DATE) - interval '18 month')::date, 2500000.00);

-- Invoices (revenue / AR). One candidate row per active customer per month,
-- kept with ~55% probability, priced by segment and grown ~3.5% per month.
WITH months AS (
    SELECT gs AS midx,
           (date_trunc('month', CURRENT_DATE) - ((17 - gs) * interval '1 month'))::date AS m
    FROM generate_series(0, 17) gs
),
cand AS (
    SELECT c.id AS customer_id,
           c.segment,
           mo.midx,
           (mo.m + ((random()*27)::int) * interval '1 day')::date AS issue_date
    FROM customers c
    CROSS JOIN months mo
    WHERE mo.m >= date_trunc('month', c.created_at)
      AND random() < 0.70
),
priced AS (
    SELECT customer_id,
           (ARRAY['Platform','Add-ons','Professional Services','Support'])[1 + (random()*3)::int] AS product,
           issue_date,
           (issue_date + interval '30 days')::date AS due_date,
           round((CASE segment
                      WHEN 'Enterprise'  THEN 9000
                      WHEN 'Mid-Market'  THEN 3800
                      ELSE 1100
                  END * (0.6 + random()*0.8) * (1 + 0.03*midx))::numeric, 2) AS amount,
           CASE WHEN random() < 0.85
                THEN (issue_date + ((random()*45)::int) * interval '1 day')::date
                ELSE NULL
           END AS paid_raw
    FROM cand
)
INSERT INTO invoices (customer_id, product, issue_date, due_date, paid_date, amount, status)
SELECT customer_id, product, issue_date, due_date,
       CASE WHEN paid_raw <= CURRENT_DATE THEN paid_raw END AS paid_date,
       amount,
       CASE WHEN paid_raw IS NOT NULL AND paid_raw <= CURRENT_DATE THEN 'paid'
            WHEN due_date < CURRENT_DATE                            THEN 'overdue'
            ELSE 'open'
       END AS status
FROM priced;

-- Operating expenses. One row per category per month, baselines grown ~1.2%/mo.
WITH months AS (
    SELECT gs AS midx,
           (date_trunc('month', CURRENT_DATE) - ((17 - gs) * interval '1 month'))::date AS m
    FROM generate_series(0, 17) gs
),
cats(category, department, vendor, baseline) AS (
    VALUES
        ('Payroll',               'G&A',         'ADP',           100000),
        ('Marketing',             'Marketing',   'HubSpot',        28000),
        ('Cloud Infrastructure',  'Engineering', 'AWS',            15000),
        ('Software & SaaS',       'G&A',         'Various SaaS',    8000),
        ('Office & Rent',         'Ops',         'WeWork',         12000),
        ('Travel',                'Sales',       'Concur',          5000),
        ('Professional Services', 'G&A',         'Deloitte',        7000)
)
INSERT INTO expenses (category, department, vendor, incurred_at, paid_date, amount)
SELECT cats.category, cats.department, cats.vendor,
       (mo.m + ((random()*5)::int) * interval '1 day')::date AS incurred_at,
       (mo.m + ((8 + random()*12)::int) * interval '1 day')::date AS paid_date,
       round((cats.baseline * (1 + 0.012*mo.midx) * (0.9 + random()*0.2))::numeric, 2) AS amount
FROM cats CROSS JOIN months mo;

-- Budgets: the plan, set ~5% above each category's baseline trajectory.
WITH months AS (
    SELECT gs AS midx,
           (date_trunc('month', CURRENT_DATE) - ((17 - gs) * interval '1 month'))::date AS m
    FROM generate_series(0, 17) gs
),
cats(category, baseline) AS (
    VALUES
        ('Payroll',               100000),
        ('Marketing',              28000),
        ('Cloud Infrastructure',   15000),
        ('Software & SaaS',         8000),
        ('Office & Rent',          12000),
        ('Travel',                  5000),
        ('Professional Services',   7000)
)
INSERT INTO budgets (category, period_month, budgeted)
SELECT cats.category, mo.m,
       round((cats.baseline * (1 + 0.012*mo.midx) * 1.05)::numeric, -2)
FROM cats CROSS JOIN months mo;
