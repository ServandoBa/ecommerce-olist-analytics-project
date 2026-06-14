WITH raw_products_stg AS (
select 
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    loaded_ts_utc
from {{ source ('raw_tables', 'raw_products') }} ),
order_products_stg_1 as (
    select 
        trim(product_id) as product_id,
        lower(trim(product_category_name)) as product_category_name,
        cast(product_name_lenght as numeric) as product_name_length,
        cast(product_description_lenght as numeric) as product_description_length,
        cast(product_photos_qty as numeric) as product_photos_qty,
        cast(product_weight_g as numeric) as product_weight_g,
        cast(product_length_cm as numeric) as product_length_cm,
        cast(product_height_cm as numeric) as product_height_cm,
        cast(product_width_cm as numeric) as product_width_cm,
        loaded_ts_utc
    from raw_products_stg),
raw_product_category_name_translation_stg as (
   select 
        product_category_name,
        product_category_name_english,
        loaded_ts_utc
    from {{ source ('raw_tables', 'raw_product_category_name_translation') }} ),
product_category_name_translation_stg_1 as (
    select 
        lower(trim(product_category_name)) as product_category_name,
        lower(trim(product_category_name_english)) as product_category_name_english, 
    from raw_product_category_name_translation_stg
    ),
order_products_stg_2 as (
    select 
        product_id,
        p.product_category_name,
        product_category_name_english,
        product_name_length,
        product_description_length,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm,
        loaded_ts_utc
    from order_products_stg_1 as p
    left join product_category_name_translation_stg_1 as c 
        on c.product_category_name = p.product_category_name
)


select *
from order_products_stg_2