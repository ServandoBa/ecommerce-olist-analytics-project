with orders as (
    select order_id
    from {{ ref('stg_orders') }}
),

order_items as (
    select
        order_id,
        order_item_id,
        price as item_price_amt,
        freight_value as item_freight_amt,
        price + freight_value as item_revenue_amt
    from {{ ref('stg_order_items') }}
),

order_items_amt as (
    select
        order_id,
        count(*) as order_items_count,
        sum(item_price_amt) as order_gmv_amt,
        sum(item_freight_amt) as order_freight_amt,
        sum(item_revenue_amt) as order_revenue_amt
    from order_items
    group by order_id
),

order_payments_amt as (
    select
        order_id,
        count(*) as payment_records_count,
        sum(payment_value) as order_payment_amt
    from {{ ref('stg_order_payments') }}
    group by order_id
),

int_order_amt as (
    select
        orders.order_id,
        coalesce(items.order_items_count, 0) as order_items_count,
        coalesce(payments.payment_records_count, 0) as payment_records_count,
        coalesce(items.order_gmv_amt, 0) as order_gmv_amt,
        coalesce(items.order_freight_amt, 0) as order_freight_amt,
        coalesce(items.order_revenue_amt, 0) as order_revenue_amt,
        coalesce(payments.order_payment_amt, 0) as order_payment_amt,
        round(coalesce(items.order_revenue_amt, 0) - coalesce(payments.order_payment_amt, 0), 2) as order_revenue_payment_diff_amt,
        case when items.order_id is not null then 1 else 0 end as has_order_items_ind,
        case when payments.order_id is not null then 1 else 0 end as has_payment_ind,
        case
            when abs(coalesce(items.order_revenue_amt, 0) - coalesce(payments.order_payment_amt, 0)) <= 0.01 then 1
            else 0
        end as revenue_matches_payment_ind
    from orders
    left join order_items_amt as items
        on orders.order_id = items.order_id
    left join order_payments_amt as payments
        on orders.order_id = payments.order_id
)

select *
from int_order_amt