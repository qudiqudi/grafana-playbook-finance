-- Finance schema for the Grafana playbook.
-- Intentionally small and readable: four base tables plus a handful of views.
-- Every dashboard query is written against these objects, so the SQL doubles
-- as documentation of how each metric is defined.

CREATE TABLE customers (
    id          SERIAL PRIMARY KEY,
    name        TEXT NOT NULL,
    region      TEXT NOT NULL,          -- North America, EMEA, APAC, LATAM
    segment     TEXT NOT NULL,          -- Enterprise, Mid-Market, SMB
    created_at  DATE NOT NULL
);

-- Accounts receivable: money customers owe / have paid us. Revenue lives here.
CREATE TABLE invoices (
    id           SERIAL PRIMARY KEY,
    customer_id  INTEGER NOT NULL REFERENCES customers(id),
    product      TEXT NOT NULL,         -- Platform, Add-ons, Professional Services, Support
    issue_date   DATE NOT NULL,
    due_date     DATE NOT NULL,
    paid_date    DATE,                  -- NULL while still outstanding
    amount       NUMERIC(12,2) NOT NULL,
    status       TEXT NOT NULL          -- paid, open, overdue
);

-- Accounts payable / operating expenses: money going out.
CREATE TABLE expenses (
    id           SERIAL PRIMARY KEY,
    category     TEXT NOT NULL,         -- Payroll, Marketing, Cloud Infrastructure, ...
    department   TEXT NOT NULL,         -- Engineering, Sales, Marketing, G&A, Ops
    vendor       TEXT NOT NULL,
    incurred_at  DATE NOT NULL,
    paid_date    DATE,
    amount       NUMERIC(12,2) NOT NULL
);

-- Planned spend per expense category per month, for budget-vs-actual.
CREATE TABLE budgets (
    id            SERIAL PRIMARY KEY,
    category      TEXT NOT NULL,
    period_month  DATE NOT NULL,        -- first day of the month
    budgeted      NUMERIC(12,2) NOT NULL,
    UNIQUE (category, period_month)
);

-- Opening cash position the cash-flow dashboard builds on top of.
CREATE TABLE cash_opening (
    as_of    DATE PRIMARY KEY,
    balance  NUMERIC(14,2) NOT NULL
);

CREATE INDEX idx_invoices_issue   ON invoices (issue_date);
CREATE INDEX idx_invoices_paid    ON invoices (paid_date);
CREATE INDEX idx_expenses_incur   ON expenses (incurred_at);

-- ---------------------------------------------------------------------------
-- Views: monthly roll-ups. Dashboards mostly read from these.
-- ---------------------------------------------------------------------------

-- Recognized revenue by month (based on invoice issue date).
CREATE VIEW v_monthly_revenue AS
SELECT date_trunc('month', issue_date)::date AS month,
       SUM(amount)                            AS revenue
FROM invoices
GROUP BY 1;

-- Operating expenses by month.
CREATE VIEW v_monthly_expenses AS
SELECT date_trunc('month', incurred_at)::date AS month,
       SUM(amount)                             AS expenses
FROM expenses
GROUP BY 1;

-- Net profit / (loss) and gross margin per month.
CREATE VIEW v_monthly_pnl AS
SELECT COALESCE(r.month, e.month)              AS month,
       COALESCE(r.revenue, 0)                  AS revenue,
       COALESCE(e.expenses, 0)                 AS expenses,
       COALESCE(r.revenue, 0) - COALESCE(e.expenses, 0) AS net_profit
FROM v_monthly_revenue r
FULL OUTER JOIN v_monthly_expenses e USING (month);

-- Cash collected (invoices actually paid) vs cash paid out, by month.
CREATE VIEW v_monthly_cashflow AS
WITH inflow AS (
    SELECT date_trunc('month', paid_date)::date AS month, SUM(amount) AS cash_in
    FROM invoices WHERE paid_date IS NOT NULL GROUP BY 1
),
outflow AS (
    SELECT date_trunc('month', COALESCE(paid_date, incurred_at))::date AS month,
           SUM(amount) AS cash_out
    FROM expenses GROUP BY 1
)
SELECT COALESCE(i.month, o.month) AS month,
       COALESCE(i.cash_in, 0)     AS cash_in,
       COALESCE(o.cash_out, 0)    AS cash_out,
       COALESCE(i.cash_in, 0) - COALESCE(o.cash_out, 0) AS net_cash_flow
FROM inflow i FULL OUTER JOIN outflow o USING (month);

-- Running cash balance = opening balance + cumulative net cash flow.
CREATE VIEW v_cash_balance AS
SELECT cf.month,
       (SELECT balance FROM cash_opening ORDER BY as_of LIMIT 1)
         + SUM(cf.net_cash_flow) OVER (ORDER BY cf.month) AS cash_balance
FROM v_monthly_cashflow cf;
