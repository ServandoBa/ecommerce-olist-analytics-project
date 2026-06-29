with sellers as (
    select
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state
    from {{ ref('stg_sellers') }}
)

select
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state,
    current_timestamp() as loaded_ts_utc
from sellers