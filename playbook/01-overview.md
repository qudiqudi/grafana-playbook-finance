# 1. Overview

This playbook is a working reference for putting business finance data in front of
the people who need it: founders, finance teams, and operators. It's opinionated
about what to show and how, and every recommendation is backed by a real dashboard
and the SQL behind it.

## Who each dashboard is for

- Executive Overview — the weekly/monthly leadership read. One screen: are we
  growing, are we profitable, how much cash do we have, how long does it last.
- Revenue & Sales — for go-to-market and finance. Where revenue comes from, which
  segments and regions drive it, who the biggest customers are.
- Cash Flow — for finance and the board. Cash in vs cash out, running balance,
  and how much you're owed (AR aging). Cash, not accrual, is what keeps the lights on.
- Expenses & Budget — for department heads and finance. Where money goes and
  whether you're on plan.

## Principles this playbook follows

1. Lead with the decision, not the data. The top row of every dashboard is the
   handful of numbers someone would screenshot and send to the board.

2. Accrual and cash are different stories. Revenue (invoice issued) and cash
   collected (invoice paid) diverge, sometimes badly. We show both and never
   conflate them.

3. Every number is reproducible. The metric definitions in
   [03-metrics-and-kpis.md](03-metrics-and-kpis.md) map one-to-one to SQL you can
   read. If a board member asks "how is runway calculated?", the answer is a query,
   not a spreadsheet nobody can find.

4. Money gets a money format. Currency units, sane decimals, red for outflows and
   overdue, green for inflows and profit. Consistency across dashboards matters more
   than per-panel cleverness.

## How to read the rest of the playbook

- [02-data-sources.md](02-data-sources.md) — wiring Grafana to your finance data,
  and how to repoint these dashboards at your own warehouse.
- [03-metrics-and-kpis.md](03-metrics-and-kpis.md) — the metric definitions.
- [04-dashboard-design.md](04-dashboard-design.md) — layout, color, and panel
  choices, with the reasoning.
- [05-alerting.md](05-alerting.md) — what's worth alerting on in finance, and how.
- [06-operations.md](06-operations.md) — running this in production: refresh,
  performance, access control, and trust.
