
## 1. Business questions

Questions the analytical layer is built to answer, grouped by domain.

### Commercial
- How does monthly GMV trend, and which categories and states drive it?
- What is the AOV, and how does it vary by category, state, and payment type? 

### Logistics & delivery
- What is the on-time delivery rate, and how does it trend over time by seller?
- Which delivery routes have the worst operational performance?
- How long does each order fulfillment stage take?

### Customer experience & reviews
- Does late delivery drive low review scores? 
- How are review scores distributed, and how do they trend?

### Seller & marketplace
- How concentrated is GMV across sellers?
- Which sellers underperform on delivery and reviews?

### Customer behavior
- What is the repurchase rate and the time between orders?
- What is the percentage of inactive customers?
- What share of revenue comes from one-time vs recurring customers?


## 2. Data understanding (data profiling)

### Dataset volume

 Counts reflect the **initial static load**. Synthetic incremental records will be appended later to exercise incremental models; these are the pre-incremental baselines.

| Source | Rows |
|---|--:|
| orders | 99,441 |
| customers | 99,441 |
| order_items | 112,650 |
| order_payments | 103,886 |
| order_reviews | 99,224 |
| products | 32,951 |
| sellers | 3,095 |
| geolocation | 1,000,163 |
| product_category_name_translation | 71 |

- **Order purchase window:** 2016-09-04 → 2018-10-17 

### Key distributions

**Orders** 
- Status: delivered 96,478 | shipped 1,107 | canceled 625 | unavailable 609 | invoiced 314 | processing 301 | created 5 | approved 2. 
- Purchase date (year): 2016: 329 | 2017: 45101 | 2018: 54011 
- Delivered orders: 97% of total orders
- Delivery time: median 10 days, average 12.5 days, Positive skewness.


**Customers**
- 99,441 `customer_id` (link with orders table) but only 96,096 `customer_unique_id`. Repeat customers: 2,997, max 17 orders. 
- State count: 27 states
- Top 3 States: SP 41,746 | RJ 12,852 | MG 11,635.


**Order items**
- Basket size: 1.14 items per order_id in average.
- 90.1% are single-item orders
- Max ordered products by order: 21. 


**Payments** 
- Payment distirbution: credit_card 76,795 | boleto 19,784 | voucher 5,775 | debit_card 1,529 | not_defined 3. 
- Installments: mean 3.5 for credit_card, max 24. 


**Reviews** 
- Score dist: 5→ 57,328 (58%) · 4→ 19,142 (19%) · 3→ 8,179 (8%) | 2→ 3,151 (3%) | 1→ 11,424 (12%). 
- 99.2% of orders have a review. 
- 41.3% include a text comment.

**Products / english category catalog**
- 32,951 products
- 73 raw categories 
- 2 categories with no English translation (`pc_gamer`, `portateis_cozinha_e_preparadores_de_alimentos`). 


**Sellers**
- 3,095 sellers across 23 states. 
- Top 3 States w/more sellers: SP 1849 (59.7%) | PR 349 (11.3%) | MG 244 (7.9%)

**Geolocation**
- 1,000,163 rows but only 19,015 unique zip prefixes (not unique by design). 
- Several latitude and longitude values for the same zip prefix.



### Data quality findings → modeling decisions

This table is the implementation spec for the intermediate layer.

| # | Finding | Decision |
|---|---|---|
| 1 | `review_id` has 814 dups, `order_id` 551 dups in reviews | Deduplicate to 1 row per order (latest by `review_answer_timestamp`) |
| 2 | `customer_id` is per-order (99,441 = 1:1 orders); real entity is `customer_unique_id` (96,096) | Grain = `customer_unique_id` |
| 3 | Geolocation: 1M rows, 19,015 non-unique prefixes | Aggregate to a centroid (avg lat/lng) per prefix for `dim_geography`; keep raw grain for density-map analysis |
| 4 | 775 orders without items, 1 without payment | Keep in `fct_orders` via left joins |
| 5 | 610 products without category; 2 categories without translation | Coalesce `'uncategorized'`; keep Portuguese name when no translation |
| 6 | Items+freight reconciles 99.6% to the cent vs payments | Revenue = price + freight_value |
| 7 | 8 delivered orders have no `delivered_customer_date` | Compute on-time/delivery-days only when date present; add flag for these cases |





