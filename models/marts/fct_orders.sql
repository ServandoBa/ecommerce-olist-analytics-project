with orders as (
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
),

fulfillment as (
    select
        order_id,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date,
        delivered_order_ind,
        has_customer_delivery_date_ind,
        delivered_order_missing_delivery_date_ind,
        hours_between_purchase_and_approval,
        days_between_purchase_and_approval,
        hours_between_approval_and_carrier,
        days_between_approval_and_carrier,
        hours_between_carrier_and_customer,
        days_between_carrier_and_customer,
        hours_between_purchase_and_delivery,
        days_between_purchase_and_delivery,
        hours_delivery_vs_estimated,
        days_delivery_vs_estimated,
        on_time_delivery_ind,
        late_delivery_ind,
        days_delivered_after_estimated_on_late_delivery,
        first_review_date,
        last_review_date,
        last_review_answer_timestamp,
        days_between_first_and_last_reviews,
        days_between_delivery_and_last_review
    from {{ ref('int_orders_fulfillment') }}
),

amounts as (
    select
        order_id,
        order_items_count,
        payment_records_count,
        order_gmv_amt,
        order_freight_amt,
        order_revenue_amt,
        order_payment_amt,
        order_revenue_payment_diff_amt,
        has_order_items_ind,
        has_payment_ind,
        revenue_matches_payment_ind
    from {{ ref('int_orders_amt') }}
)

select
    fulfillment.order_id,
    customer_dim.customer_unique_id,
    date(fulfillment.order_purchase_timestamp) as order_date_key,
    fulfillment.order_status,
    fulfillment.order_purchase_timestamp,
    fulfillment.order_approved_at,
    fulfillment.order_delivered_carrier_date,
    fulfillment.order_delivered_customer_date,
    fulfillment.order_estimated_delivery_date,
    amounts.order_gmv_amt as gmv_amt,
    amounts.order_freight_amt as freight_amt,
    amounts.order_revenue_amt as revenue_amt,
    amounts.order_payment_amt as payment_amt,
    amounts.order_revenue_payment_diff_amt as revenue_payment_diff_amt,
    amounts.order_items_count,
    amounts.payment_records_count,
    amounts.has_order_items_ind,
    amounts.has_payment_ind,
    amounts.revenue_matches_payment_ind,
    fulfillment.delivered_order_ind,
    fulfillment.has_customer_delivery_date_ind,
    fulfillment.delivered_order_missing_delivery_date_ind,
    fulfillment.on_time_delivery_ind,
    fulfillment.late_delivery_ind,
    fulfillment.hours_between_purchase_and_approval,
    fulfillment.days_between_purchase_and_approval,
    fulfillment.hours_between_approval_and_carrier,
    fulfillment.days_between_approval_and_carrier,
    fulfillment.hours_between_carrier_and_customer,
    fulfillment.days_between_carrier_and_customer,
    fulfillment.hours_between_purchase_and_delivery,
    fulfillment.days_between_purchase_and_delivery,
    fulfillment.hours_delivery_vs_estimated,
    fulfillment.days_delivery_vs_estimated,
    fulfillment.days_delivered_after_estimated_on_late_delivery,
    fulfillment.first_review_date,
    fulfillment.last_review_date,
    fulfillment.last_review_answer_timestamp,
    fulfillment.days_between_first_and_last_reviews,
    fulfillment.days_between_delivery_and_last_review,
    current_timestamp() as loaded_ts_utc
from fulfillment
left join amounts
    on fulfillment.order_id = amounts.order_id
left join orders
    on fulfillment.order_id = orders.order_id
left join customers
    on orders.customer_id = customers.customer_id
left join customer_dim
    on customers.customer_unique_id = customer_dim.customer_unique_id