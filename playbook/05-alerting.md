# 5. Alerting

Finance alerts are different from infra alerts. Most finance metrics move on a
monthly cadence, so a 5-minute evaluation loop is pointless and noisy. Alert on
things that are genuinely actionable when they fire, and route them to a human who
can do something about it.

## What's worth alerting on

High value, low noise:

- Runway below threshold. The single most important finance alert. When months of
  OpEx covered drops under, say, 9 (warn) or 6 (critical), leadership needs to know
  now, not at month-end.
- Cash balance below a floor. A hard minimum the business must not cross.
- Overdue AR spike. A large jump in overdue receivables, or any single large invoice
  crossing 60/90 days, is a collections action item.
- Budget overrun. A category exceeding budget by more than X% for the month, caught
  early enough to course-correct.
- Net cash flow negative for N consecutive months when you expected to be cash
  positive — a trend alert, not a single-month blip.

Operational (if you wire up Prometheus), where fast evaluation does make sense:

- Payment success rate drops below a threshold — you may be losing revenue right now.
- Payment/webhook processing lag rising — cash is being collected but not recorded.

## How to set it up in Grafana

Grafana unified alerting evaluates a query on a schedule and fires when a condition
holds. For a runway alert against `finance-postgres`:

```sql
SELECT (SELECT cash_balance FROM v_cash_balance ORDER BY month DESC LIMIT 1)
       / NULLIF(AVG(expenses), 0) AS runway_months
FROM v_monthly_expenses
WHERE month >= date_trunc('month', CURRENT_DATE) - interval '3 month';
```

Condition: `runway_months < 6`. Evaluate every few hours (not seconds) — the inputs
only change as invoices and expenses land. Add a "for" duration so a transient
recalculation doesn't page anyone.

## Routing and noise control

- Send finance alerts to the finance/leadership channel, not the on-call infra
  rotation. Different audience, different urgency.
- Prefer daily digests for slow-moving metrics (budget variance, AR aging) and
  immediate notification only for the few critical thresholds (runway, cash floor).
- Always include the current value and the threshold in the alert message, and link
  back to the dashboard so the reader gets context in one click.
- Set thresholds off the actual plan, and revisit them each planning cycle. A runway
  alert calibrated to last year's burn will either cry wolf or stay silent when it
  matters.

## What not to alert on

Don't alert on revenue being "lower than yesterday," daily cash fluctuations, or any
metric whose normal variance is larger than the thing you're trying to catch. Those
belong on a dashboard someone reviews, not in a notification that trains people to
ignore alerts.
