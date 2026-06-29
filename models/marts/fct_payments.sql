with payments as (
    select
        order_payment_seq_sk,
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value
    from {{ ref('stg_order_payments') }}
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
    payments.order_payment_seq_sk,
    payments.order_id,
    payments.payment_sequential,
    customer_dim.customer_unique_id,
    date(orders.order_purchase_timestamp) as order_date_key,
    payments.payment_type,
    payments.payment_installments as installments,
    payments.payment_value as payment_value_amt,
    current_timestamp() as loaded_ts_utc
from payments
left join orders
    on payments.order_id = orders.order_id
left join customers
    on orders.customer_id = customers.customer_id
left join customer_dim
    on customers.customer_unique_id = customer_dim.customer_unique_id