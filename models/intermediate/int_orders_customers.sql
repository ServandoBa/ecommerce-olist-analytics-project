with int_orders_customers as (
    select
       o.order_id,
       o.customer_id, 
       o.order_status,
       o.order_purchase_timestamp,
       oc.customer_unique_id,
       oc.customer_zip_code_prefix,
       oc.customer_city,
       oc.customer_state
    from {{ ref('stg_orders') }} as o
    left join {{ ref('stg_customers') }} as oc on oc.customer_id = o.customer_id
),
int_orders_customers_1 as (
    select 
        customer_unique_id, 
        max(order_purchase_timestamp) as last_purchase,
        count(distinct order_id) as total_orders
    from int_orders_customers
    group by 1
),
date_reference as (
    select max(order_purchase_timestamp) as ref_date
    from int_orders_customers
),
cust_orders_diff as (
select 
    oic.customer_unique_id,
    oic.last_purchase,
    dr.ref_date,
    round(date_diff( dr.ref_date, oic.last_purchase, hour)/24,1) as days_since_last_order,
    oic.total_orders   
from int_orders_customers_1 oic, date_reference dr
),
cust_clustering as (
select 
    customer_unique_id,
    last_purchase,
    days_since_last_order,
    case 
        when days_since_last_orders <= 180 then 'active'
        else  'sleep'
    end as customer_cluster
from cust_orders_diff)


select 
    orders_cust.*,
    cc.last_purchase,
    cc.days_since_last_orders,
    cc.customer_cluster
from {{ ref('stg_customers') }} orders_cust
left join cust_clustering cc on orders_cust.customer_unique_id = cc.customer_unique_id
