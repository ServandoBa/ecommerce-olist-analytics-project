with int_orders_fulfillment as (
    select
        o.order_id, 
        o.order_status,
        o.order_purchase_timestamp,
        --purchase to approved
        o.order_approved_at, 
        date_diff( o.order_approved_at, o.order_purchase_timestamp, hour) hours_between_purchase_and_approval,
        round(date_diff( o.order_approved_at, o.order_purchase_timestamp, hour)/24,1) as  days_between_purchase_and_approval, 
        --approved to carrier
        o.order_delivered_carrier_date,
        date_diff( o.order_delivered_carrier_date, o.order_approved_at, hour) hours_between_carrier_and_approval,
        round(date_diff( o.order_delivered_carrier_date, o.order_approved_at, hour)/24,1) as  days_between_carrier_and_approval, 
        --carrier to delivered
        o.order_delivered_customer_date,
        date_diff( o.order_delivered_customer_date, o.order_delivered_carrier_date, hour) hours_between_carrier_and_approval,
        round(date_diff( o.order_delivered_customer_date, o.order_delivered_carrier_date, hour)/24,1) as  days_between_carrier_and_approval,
        o.order_estimated_delivery_date,
        case when  o.order_delivered_customer_date is null then 0
            when o.order_delivered_customer_date <= o.order_estimated_delivery_date then 1 
            else 0 
        end as on_time_delivery_ind, 
    from {{ ref('stg_orders') }} as o 
),
int_orders_fulfillment_1 as (
    select *,
        case when order_status = 'delivered' and on_time_delivery_ind = 0 then  round(date_diff(order_delivered_customer_date, order_estimated_delivery_date, hour)/24,1)
            else 0
        end days_delivered_after_estimated_on_late_delivery,
        round(date_diff(order_delivered_customer_date, order_purchase_timestamp, hour)/24, 2) as days_operative_lifecycle_order
    from int_orders_fulfillment
),
int_orders_fulfillment_2 as (
    select 
        iof.*,
        orev.first_review_date, 
        orev.last_review_date,
        orev.days_between_first_and_last_reviews,
        date_diff(orev.last_review_date, order_delivered_customer_date, day) as days_post_lifecycle_order
    from int_orders_fulfillment_1 as iof
    left join {{ ref('int_orders_reviews') }} as orev 
        on iof.order_id = orev.order_id
)

#PENDIENTE TERMINAR
select *
from int_orders_fulfillment_2
where order_status = 'delivered'