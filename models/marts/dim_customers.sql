with customers as (
    select
        customer_unique_id,
        latest_customer_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        customer_id_count,
        total_orders,
        delivered_orders_count,
        first_purchase_timestamp,
        last_purchase_timestamp,
        days_since_last_order,
        repeat_customer_ind,
        customer_recency_segment,
        customer_zip_code_prefix_count,
        customer_city_count,
        customer_state_count
    from {{ ref('int_orders_customers') }}
)

select
    customer_unique_id,
    latest_customer_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    customer_id_count,
    total_orders,
    delivered_orders_count,
    first_purchase_timestamp,
    last_purchase_timestamp,
    days_since_last_order,
    repeat_customer_ind,
    customer_recency_segment,
    customer_zip_code_prefix_count,
    customer_city_count,
    customer_state_count,
    current_timestamp() as loaded_ts_utc
from customers