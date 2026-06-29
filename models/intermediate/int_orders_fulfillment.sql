with orders as (
    select
        order_id,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date,
        loaded_ts_utc
    from {{ ref('stg_orders') }}
),

order_fulfillment as (
    select
        order_id,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date,
        case when order_status = 'delivered' then 1 else 0 end as delivered_order_ind,
        case when order_delivered_customer_date is not null then 1 else 0 end as has_customer_delivery_date_ind,
        case
            when order_status = 'delivered' and order_delivered_customer_date is null then 1
            else 0
        end as delivered_order_missing_delivery_date_ind,
        timestamp_diff(order_approved_at, order_purchase_timestamp, hour) as hours_between_purchase_and_approval,
        round(timestamp_diff(order_approved_at, order_purchase_timestamp, hour) / 24, 1) as days_between_purchase_and_approval,
        timestamp_diff(order_delivered_carrier_date, order_approved_at, hour) as hours_between_approval_and_carrier,
        round(timestamp_diff(order_delivered_carrier_date, order_approved_at, hour) / 24, 1) as days_between_approval_and_carrier,
        timestamp_diff(order_delivered_customer_date, order_delivered_carrier_date, hour) as hours_between_carrier_and_customer,
        round(timestamp_diff(order_delivered_customer_date, order_delivered_carrier_date, hour) / 24, 1) as days_between_carrier_and_customer,
        timestamp_diff(order_delivered_customer_date, order_purchase_timestamp, hour) as hours_between_purchase_and_delivery,
        round(timestamp_diff(order_delivered_customer_date, order_purchase_timestamp, hour) / 24, 2) as days_between_purchase_and_delivery,
        timestamp_diff(order_delivered_customer_date, order_estimated_delivery_date, hour) as hours_delivery_vs_estimated,
        round(timestamp_diff(order_delivered_customer_date, order_estimated_delivery_date, hour) / 24, 1) as days_delivery_vs_estimated,
        case
            when order_delivered_customer_date is null then null
            when date(order_delivered_customer_date) <= date(order_estimated_delivery_date) then 1
            else 0
        end as on_time_delivery_ind,
        case
            when order_delivered_customer_date is null then null
            when date(order_delivered_customer_date) > date(order_estimated_delivery_date) then 1
            else 0
        end as late_delivery_ind,
        loaded_ts_utc
    from orders
),

order_fulfillment_enriched as (
    select
        fulfillment.order_id,
        fulfillment.order_status,
        fulfillment.order_purchase_timestamp,
        fulfillment.order_approved_at,
        fulfillment.order_delivered_carrier_date,
        fulfillment.order_delivered_customer_date,
        fulfillment.order_estimated_delivery_date,
        fulfillment.delivered_order_ind,
        fulfillment.has_customer_delivery_date_ind,
        fulfillment.delivered_order_missing_delivery_date_ind,
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
        fulfillment.on_time_delivery_ind,
        fulfillment.late_delivery_ind,
        case
            when fulfillment.late_delivery_ind = 1 then fulfillment.days_delivery_vs_estimated
            else 0
        end as days_delivered_after_estimated_on_late_delivery,
        reviews.first_review_date,
        reviews.last_review_date,
        reviews.last_review_answer_timestamp,
        reviews.days_between_first_and_last_reviews,
        timestamp_diff(reviews.last_review_date, fulfillment.order_delivered_customer_date, day) as days_between_delivery_and_last_review,
        greatest(
            coalesce(fulfillment.loaded_ts_utc, reviews.loaded_ts_utc),
            coalesce(reviews.loaded_ts_utc, fulfillment.loaded_ts_utc)
        ) as loaded_ts_utc
    from order_fulfillment as fulfillment
    left join {{ ref('int_orders_reviews') }} as reviews
        on fulfillment.order_id = reviews.order_id
)

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
    days_between_delivery_and_last_review,
    loaded_ts_utc
from order_fulfillment_enriched