with products as (
    select
        product_id,
        product_category_name,
        product_category_name_english,
        product_name_length,
        product_description_length,
        product_photos_qty,
        product_weight_g,
        product_weight_kg,
        product_under_1kg_ind,
        product_over_5kg_ind,
        product_length_cm,
        product_height_cm,
        product_width_cm,
        dimensions_available_ind,
        product_volume_cm3,
        product_volumetric_weight_kg
    from {{ ref('int_products') }}
)

select
    product_id,
    product_category_name,
    product_category_name_english,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_weight_kg,
    product_under_1kg_ind,
    product_over_5kg_ind,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    dimensions_available_ind,
    product_volume_cm3,
    product_volumetric_weight_kg,
    current_timestamp() as loaded_ts_utc
from products