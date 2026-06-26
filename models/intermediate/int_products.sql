with products as (
    select
        product_id,
        product_category_name,
        product_category_name_english,
        product_name_length,
        product_description_length,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm,
        loaded_ts_utc
    from {{ ref('stg_products') }}
),

products_enriched as (
    select
        product_id,
        coalesce(product_category_name, 'uncategorized') as product_category_name,
        coalesce(product_category_name_english, product_category_name, 'uncategorized') as product_category_name_english,
        product_name_length,
        product_description_length,
        product_photos_qty,
        product_weight_g,
        product_weight_g / 1000 as product_weight_kg,
        case
            when product_weight_g is null then null
            when product_weight_g <= 1000 then 1
            else 0
        end as product_under_1kg_ind,
        case
            when product_weight_g is null then null
            when product_weight_g >= 5000 then 1
            else 0
        end as product_over_5kg_ind,
        product_length_cm,
        product_height_cm,
        product_width_cm,
        case
            when product_length_cm > 0 and product_height_cm > 0 and product_width_cm > 0 then 1
            else 0
        end as dimensions_available_ind,
        case
            when product_length_cm > 0 and product_height_cm > 0 and product_width_cm > 0
                then product_length_cm * product_height_cm * product_width_cm
            else null
        end as product_volume_cm3,
        case
            when product_length_cm > 0 and product_height_cm > 0 and product_width_cm > 0
                then product_length_cm * product_height_cm * product_width_cm / 5000
            else null
        end as product_volumetric_weight_kg,
        loaded_ts_utc
    from products
)

select *
from products_enriched