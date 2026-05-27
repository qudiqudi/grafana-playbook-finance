# 2. Data Sources

Business finance data is usually relational — invoices, payments, expenses, ledger
entries living in an application database or a warehouse. That's why these dashboards
target PostgreSQL by default. But the patterns are portable; this page covers the
common sources and how to repoint the dashboards.

## SQL databases (default)

PostgreSQL, MySQL, BigQuery, Snowflake, Redshift, and ClickHouse all use the same
core idea: dashboards run SQL, Grafana renders the result. Two macros do the heavy
lifting:

- `$__timeFilter(column)` expands to a `BETWEEN` against the dashboard's time range.
- `$__timeGroup(column, '1M')` buckets a timestamp (less needed here since we
  pre-aggregate to months in views).

The bundled stack provisions a PostgreSQL source with UID `finance-postgres`. Every
panel references that UID, which is what makes the dashboards work on first boot.

### Where finance data actually lives

You'll typically pull from one of:

- The application/billing database directly. Fine for small teams; watch out for
  running heavy analytical queries against your production OLTP database.
- A warehouse (BigQuery/Snowflake/Redshift) fed by your ETL/ELT (Fivetran, Airbyte,
  dbt). This is the right answer once queries get expensive or data spans systems
  (Stripe + QuickBooks + the app DB).
- A read replica of production, when you want live-ish data without warehouse latency
  and without hitting the primary.

## Prometheus (operational finance metrics)

Prometheus is the wrong tool for ledgers and invoices, but the right tool for
real-time operational signals that affect revenue:

- payment success / decline rate
- checkout or invoice-generation latency
- webhook processing lag from your payment provider
- failed/retried charges

Expose these from your payments service and scrape them. The stack provisions a
`finance-prometheus` source and ships an example scrape job in
[`prometheus/prometheus.yml`](../prometheus/prometheus.yml). A useful split is:
Postgres dashboards answer "how much money," Prometheus dashboards answer "is the
money machine healthy right now."

## Repointing the dashboards at your own data

1. Add your data source in Grafana (or via provisioning). Note its UID.
2. Either reuse the UID `finance-postgres` for a drop-in swap, or open each dashboard
   JSON and replace the `uid` in every `datasource` block.
3. Adjust the SQL to your schema. The queries assume the tables in
   [`sql/schema.sql`](../sql/schema.sql); the closer your model is to that shape
   (invoices, expenses, budgets), the less you'll change. Reading
   [03-metrics-and-kpis.md](03-metrics-and-kpis.md) tells you exactly what each
   query needs to produce.

## A note on credentials

The bundled stack uses `finance`/`finance` because it's a throwaway local database.
In production, use a read-only database user scoped to the finance schema, store the
password in Grafana's secrets (not in committed provisioning files), and prefer TLS
(`sslmode=require`). More in [06-operations.md](06-operations.md).
