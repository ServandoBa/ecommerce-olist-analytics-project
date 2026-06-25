with int_order_items as (
    select
        order_id,
        price,
        freight_value,
        price + freight_value as gmv
    from {{ ref('stg_order_items') }}
),
int_order_items_amt as (
    select
        order_id,
        sum(price) as total_price_amt,
        sum(freight_value) as total_freight_amt,
        sum(gmv) as total_gmv
    from int_order_items
    group by 1
),
int_order_payments_amt as (
    select 
        order_id,
        sum(payment_value) as total_payment_amt
    from {{ ref('stg_order_payments') }}
    group by 1
),
int_order_amt as (
    select 
        oia.*,
        opa.total_payment_amt
    from int_order_items_amt as oia
    left join int_order_payments_amt as opa on opa.order_id = oia.order_id
)

select *
from int_order_amt