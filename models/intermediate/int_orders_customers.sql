with orders_customers as (
    select
        orders.order_id,
        orders.customer_id,
        customers.customer_unique_id,
        customers.customer_zip_code_prefix,
        customers.customer_city,
        customers.customer_state,
        orders.order_status,
        orders.order_purchase_timestamp,
        orders.loaded_ts_utc as orders_loaded_ts_utc,
        customers.loaded_ts_utc as customers_loaded_ts_utc
    from {{ ref('stg_orders') }} as orders
    left join {{ ref('stg_customers') }} as customers
        on orders.customer_id = customers.customer_id
),

ranked_customer_orders as (
    select
        *,
        row_number() over (
            partition by customer_unique_id
            order by order_purchase_timestamp desc, order_id desc
        ) as rn
    from orders_customers
),

customer_order_agg as (
    select
        customer_unique_id,
        count(distinct customer_id) as customer_id_count,
        count(distinct order_id) as total_orders,
        min(order_purchase_timestamp) as first_purchase_timestamp,
        max(order_purchase_timestamp) as last_purchase_timestamp,
        countif(order_status = 'delivered') as delivered_orders_count,
        count(distinct customer_zip_code_prefix) as customer_zip_code_prefix_count,
        count(distinct customer_city) as customer_city_count,
        count(distinct customer_state) as customer_state_count,
        greatest(
            coalesce(max(orders_loaded_ts_utc), max(customers_loaded_ts_utc)),
            coalesce(max(customers_loaded_ts_utc), max(orders_loaded_ts_utc))
        ) as loaded_ts_utc
    from orders_customers
    group by customer_unique_id
),

date_reference as (
    select max(order_purchase_timestamp) as ref_purchase_timestamp
    from orders_customers
),

int_orders_customers_final as (
    select
        latest.customer_unique_id,
        latest.customer_id as latest_customer_id,
        latest.customer_zip_code_prefix,
        latest.customer_city,
        latest.customer_state,
        agg.customer_id_count,
        agg.total_orders,
        agg.delivered_orders_count,
        agg.first_purchase_timestamp,
        agg.last_purchase_timestamp,
        round(timestamp_diff(ref.ref_purchase_timestamp, agg.last_purchase_timestamp, hour) / 24, 1) as days_since_last_order,
        case when agg.total_orders > 1 then 1 else 0 end as repeat_customer_ind,
        case
            when timestamp_diff(ref.ref_purchase_timestamp, agg.last_purchase_timestamp, day) <= 180 then 'active'
            else 'inactive'
        end as customer_recency_segment,
        agg.customer_zip_code_prefix_count,
        agg.customer_city_count,
        agg.customer_state_count,
        agg.loaded_ts_utc
    from ranked_customer_orders as latest
    left join customer_order_agg as agg
        on latest.customer_unique_id = agg.customer_unique_id
    cross join date_reference as ref
    where latest.rn = 1
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
    loaded_ts_utc
from int_orders_customers_final