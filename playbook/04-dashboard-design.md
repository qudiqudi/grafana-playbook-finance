# 4. Dashboard Design

Finance dashboards get screenshotted into board decks and stared at in tense
meetings. Design for that: legible at a glance, honest about what's good and bad,
consistent so people build muscle memory.

## Layout: most important, top-left

Eyes start top-left. Put the few numbers someone would text the CEO there as stat
panels, then trends below, then breakdowns (by segment, region, category) at the
bottom for the people who want to dig.

Every dashboard here follows the same skeleton:

```
[ stat ][ stat ][ stat ][ stat ]   <- the headline numbers
[   trend over time    ][ trend ]   <- where it's heading
[ breakdown ][ breakdown ][ table ] <- where it comes from
```

## Color carries meaning, so spend it carefully

- Green = good / inflow / profit. Red = bad / outflow / overdue / over budget.
- Blue = neutral balances (cash). Don't make everything a rainbow; the eye should
  jump straight to a red cell.
- Use thresholds on stat panels so a number turns red on its own. Net profit below
  zero, runway under 6 months, and any overdue AR all flip color without anyone
  reading the digits.

## Panel choices

- Stat for single headline numbers. Add a sparkline (`graphMode: area`) for the ones
  where the trend matters as much as the value (revenue, cash balance).
- Time series (lines) for balances and trends that should feel continuous (cash
  balance, revenue trend).
- Time series (bars) for discrete per-period quantities (monthly net profit, cash
  in vs out). Bars say "these are separate months," lines say "this is one moving
  quantity." Stacked bars for composition over time (revenue by segment, expenses
  by category).
- Pie/donut only for part-to-whole at a single point in time (revenue by product
  this period). Never use pie for trends.
- Table for ranked detail (top customers, AR aging, budget vs actual by category),
  with color-background cells so the worst rows pop.

## Time range and granularity

These dashboards default to `now-18M` to `now` and pre-aggregate to months in SQL
views. Finance is a monthly-rhythm business — daily noise hides the signal. Keep the
time picker available so anyone can zoom, but default to the cadence people actually
plan in.

## Formatting details that matter

- Currency unit (`currencyUSD`) and `decimals: 0` on money — nobody needs cents on a
  $2.3M cash balance.
- Percent unit with one decimal for margins and rates.
- Multi-series tooltips sorted descending, so the biggest contributor is on top.
- Consistent panel titles across dashboards ("Cash Balance" means the same thing
  everywhere).

## Make it self-explanatory

A finance dashboard that needs a verbal walkthrough fails the moment it's
screenshotted. Title panels in plain language ("Runway (months of OpEx)", not
"runway_calc"), and prefer one clear metric over a clever composite nobody can
reconstruct.
