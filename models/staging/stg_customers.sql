WITH raw_customers_stg AS (
select 
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    loaded_ts_utc
from {{ source ('raw_tables', 'raw_customers') }}),

customers_stg_1 AS (
select 
    trim(customer_id) as customer_id,
    trim(customer_unique_id) as customer_unique_id,
    cast(trim(customer_zip_code_prefix) as string) as customer_zip_code_prefix,
    lower(trim(customer_city)) as customer_city,
    upper(trim(customer_state)) as customer_state,
    loaded_ts_utc
from raw_customers_stg
)

select *
from customers_stg_1