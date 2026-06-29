with order_items as (
    select
        order_item_sk,
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_date,
        price,
        freight_value
    from {{ ref('stg_order_items') }}
),

orders as (
    select
        order_id,
        customer_id,
        order_purchase_timestamp
    from {{ ref('stg_orders') }}
),

customers as (
    select
        customer_id,
        customer_unique_id
    from {{ ref('stg_customers') }}
),

customer_dim as (
    select
        customer_unique_id
    from {{ ref('int_orders_customers') }}
)

select
    order_items.order_item_sk,
    order_items.order_id,
    order_items.order_item_id,
    customer_dim.customer_unique_id,
    order_items.product_id,
    order_items.seller_id,
    date(orders.order_purchase_timestamp) as order_date_key,
    order_items.shipping_limit_date,
    order_items.price as price_amt,
    order_items.freight_value as freight_amt,
    order_items.price + order_items.freight_value as item_revenue_amt,
    current_timestamp() as loaded_ts_utc
from order_items
left join orders
    on order_items.order_id = orders.order_id
left join customers
    on orders.customer_id = customers.customer_id
left join customer_dim
    on customers.customer_unique_id = customer_dim.customer_unique_id