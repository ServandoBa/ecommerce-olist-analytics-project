with geolocation as (
    select
        geolocation_zip_code_prefix,
        geolocation_lat_centroid,
        geolocation_lng_centroid,
        geolocation_city,
        geolocation_state
    from {{ ref('int_geolocation') }}
)

select
    geolocation_zip_code_prefix,
    geolocation_lat_centroid,
    geolocation_lng_centroid,
    geolocation_city,
    geolocation_state,
    current_timestamp() as loaded_ts_utc
from geolocation