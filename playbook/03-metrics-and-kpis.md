# 3. Metrics and KPIs

The definitions below are the contract. Each maps to SQL you can read in
[`sql/schema.sql`](../sql/schema.sql) (the views) or in the dashboard JSON. If two
people disagree about a number, the query is the tiebreaker.

## Revenue (recognized)

Sum of invoice amounts by the month the invoice was issued.

```sql
SELECT date_trunc('month', issue_date) AS month, SUM(amount)
FROM invoices GROUP BY 1;
```

This is accrual revenue — it counts when you earned it, not when you got paid.
Exposed as the `v_monthly_revenue` view.

## Expenses (OpEx)

Sum of expense amounts by the month incurred. View: `v_monthly_expenses`.

## Net profit / (loss)

`revenue - expenses` for the month. View: `v_monthly_pnl`. Positive is profit,
negative is a loss. This is a simplified P&L: no separate COGS, depreciation, or
taxes. Real GAAP statements are more involved; for an operating dashboard this is
the number people actually steer by.

## Net margin

`net_profit / revenue`, as a percent. Thresholds on the Executive dashboard:
red below 0, amber 0–15%, green above 15%. Tune to your business.

## Cash in / cash out / net cash flow

Cash is recognized when it moves, not when it's earned or owed.

- Cash in = invoices by `paid_date` (only paid invoices count).
- Cash out = expenses by `paid_date` (falling back to `incurred_at`).
- Net cash flow = cash in − cash out.

View: `v_monthly_cashflow`. The gap between revenue and cash-in is your collections
lag — a company can be "profitable" on paper and still run out of cash.

## Cash balance

Opening balance plus the running (cumulative) sum of net cash flow.

```sql
opening_balance + SUM(net_cash_flow) OVER (ORDER BY month)
```

View: `v_cash_balance`. This is the single most important number on the board deck.

## Runway

How many months the business can operate at the current spend level.

- True runway = `cash_balance / average_monthly_net_burn`, where burn is the cash
  you lose per month. Only meaningful when you're burning (net cash flow negative).
- Months of OpEx covered = `cash_balance / average_monthly_expenses` over the last
  3 months. This is what the Executive dashboard shows because it returns a sensible
  number whether or not you're currently profitable. It's the conservative read:
  "if revenue went to zero tomorrow, how long could we pay the bills?"

Pick one and label it clearly. We label ours "Runway (months of OpEx)" precisely so
nobody assumes it nets out revenue.

## Accounts receivable (AR)

- Outstanding AR = sum of invoice amounts where status is `open` or `overdue`.
- Overdue AR = sum where status is `overdue` (past due date, unpaid).
- AR aging = outstanding AR bucketed by how far past due: current, 1–30, 31–60,
  61–90, 90+ days. Money in the 90+ bucket is money you may never see; it's an early
  warning on both cash and customer health.

## Budget variance

`actual_spend - budgeted` for a category and period. Positive means over budget
(bad, shown red); negative means under (shown green). Watch the trend, not just the
single month — one-off timing differences are noise.

## Operational metrics (Prometheus)

Not in the seed data, but worth defining if you wire up Prometheus:

- Payment success rate = `successful_charges / total_charge_attempts`.
- Collection rate = cash collected / revenue invoiced over a trailing window.
- DSO (days sales outstanding) = average days from invoice issue to payment; rising
  DSO means collections are slowing.
