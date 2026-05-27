# 6. Operations

Running finance dashboards in production is mostly about trust: the numbers have to
be right, access has to be controlled, and the thing has to stay fast as data grows.

## Access control

Finance data is sensitive. Treat it that way:

- Use a read-only database user scoped to the finance schema. Dashboards never need
  write access, and a read-only user limits the blast radius of a bad query.
- Keep credentials out of git. The committed provisioning file uses a throwaway
  local password; in production, inject secrets via environment variables or
  Grafana's secret storage, not a checked-in YAML.
- Use Grafana folder permissions and teams. The "Finance" folder should be visible
  to finance and leadership, not the whole org. Org-level viewer-by-default plus an
  explicit finance team is a sane baseline.
- Prefer SSO and disable local accounts you don't need.

## Performance

- Pre-aggregate. The dashboards read from monthly roll-up views rather than scanning
  raw invoices every refresh. For larger datasets, make these materialized views (or
  dbt models / warehouse tables) refreshed on a schedule.
- Index the time and join columns. The schema indexes `issue_date`, `paid_date`, and
  `incurred_at` because every query filters on them.
- Don't point heavy dashboards at your production OLTP primary. Use a read replica
  or a warehouse so a curious VP dragging the time range to "5 years" doesn't slow
  down checkout.
- Set a sane dashboard refresh. Finance data updates daily at most; a 30-minute or
  hourly refresh is plenty. Per-second refresh just hammers the database for numbers
  that haven't changed.

## Correctness and trust

- Reconcile against the source of truth. Periodically check that dashboard revenue
  and cash totals match your accounting system / bank statements. A dashboard that's
  subtly wrong is worse than no dashboard.
- Mind timezones. `date_trunc('month', ...)` happens in the database's timezone; make
  sure that matches how your finance team closes the books, or month boundaries will
  be off by a few hours of transactions.
- Be explicit about partial periods. The current month is incomplete; label it or
  exclude it from "this month vs last month" comparisons so nobody reads a half-month
  as a decline.
- Version the dashboards. They live as JSON in this repo, so changes are reviewable
  in pull requests. Provisioned dashboards are read-only-ish in the UI by design —
  edit the JSON, not the live dashboard, so the repo stays the source of truth.

## Backups and reproducibility

The whole stack is declarative: schema, seed, data sources, and dashboards are all in
the repo. Tearing it down and rebuilding (`docker compose down -v && docker compose
up -d`) gives you an identical environment. Keep your real provisioning under the
same discipline — infrastructure-as-code for dashboards means you can rebuild Grafana
from scratch and get the same finance views back.
