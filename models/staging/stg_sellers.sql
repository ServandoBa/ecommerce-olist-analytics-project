WITH raw_sellers_stg AS (
select 
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state,
    loaded_ts_utc
from {{ source ('raw_tables', 'raw_sellers') }} ),
order_sellers_stg_1 as (
    select 
        trim(seller_id) as seller_id,
        trim(seller_zip_code_prefix) as seller_zip_code_prefix,
        lower(trim(seller_city)) as seller_city,
        upper(trim(seller_state)) as seller_state,
        loaded_ts_utc
    from raw_sellers_stg
)

select *
from order_sellers_stg_1