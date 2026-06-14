WITH raw_geolocation_stg AS (
select 
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state, 
    loaded_ts_utc
from {{ source ('raw_tables', 'raw_geolocation') }} ),
order_geolocation_stg_1 as (
    select 
        trim(geolocation_zip_code_prefix) as geolocation_zip_code_prefix,
        cast(geolocation_lat as numeric) as geolocation_lat,
        cast(geolocation_lng as numeric) as geolocation_lng,
        lower(trim(geolocation_city)) as geolocation_city,
        upper(trim(geolocation_state)) as geolocation_state, 
        loaded_ts_utc
    from raw_geolocation_stg
)

select *
from order_geolocation_stg_1