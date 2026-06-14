WITH raw_order_items_stg AS (
select 
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value, 
    loaded_ts_utc
from {{ source ('raw_tables', 'raw_order_items') }} ),
orders_items_stg_1 as (
    select 
         {{ dbt_utils.generate_surrogate_key(['order_id', 'order_item_id']) }} as order_item_sk,
        trim(order_id) as order_id,
        cast(order_item_id as integer) as order_item_id,
        trim(product_id) as product_id,
        trim(seller_id) as seller_id,
        cast(shipping_limit_date as timestamp) as shipping_limit_date,
        cast(price as numeric) as price,
        cast(freight_value as numeric) as freight_value,
        loaded_ts_utc
    from raw_order_items_stg
)

select *
from orders_items_stg_1