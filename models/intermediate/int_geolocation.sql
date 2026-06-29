with geolocation as (
    select
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    from {{ ref('stg_geolocation') }}
),

geolocation_centroids as (
    select
        geolocation_zip_code_prefix,
        avg(geolocation_lat) as geolocation_lat_centroid,
        avg(geolocation_lng) as geolocation_lng_centroid
    from geolocation
    group by geolocation_zip_code_prefix
),

city_counts as (
    select
        geolocation_zip_code_prefix,
        geolocation_city,
        count(*) as city_count
    from geolocation
    group by geolocation_zip_code_prefix, geolocation_city
),

city_mode as (
    select
        geolocation_zip_code_prefix,
        geolocation_city
    from city_counts
    qualify row_number() over (partition by geolocation_zip_code_prefix
        order by city_count desc, geolocation_city asc) = 1
),

state_counts as (
    select
        geolocation_zip_code_prefix,
        geolocation_state,
        count(*) as state_count
    from geolocation
    group by geolocation_zip_code_prefix, geolocation_state
),

state_mode as (
    select
        geolocation_zip_code_prefix,
        geolocation_state
    from state_counts
    qualify row_number() over (
        partition by geolocation_zip_code_prefix
        order by state_count desc, geolocation_state asc) = 1
)

select
    c.geolocation_zip_code_prefix,
    c.geolocation_lat_centroid,
    c.geolocation_lng_centroid,
    cm.geolocation_city,
    sm.geolocation_state
from geolocation_centroids as c
left join city_mode cm
    on c.geolocation_zip_code_prefix = cm.geolocation_zip_code_prefix
left join state_mode sm
    on c.geolocation_zip_code_prefix = sm.geolocation_zip_code_prefix