WITH raw_order_payments_stg AS (
select 
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value,
    loaded_ts_utc
from {{ source ('raw_tables', 'raw_order_payments') }} ),
order_payments_stg_1 as (
    select 
        {{ dbt_utils.generate_surrogate_key(['order_id', 'payment_sequential']) }} as order_payment_seq_sk,
        trim(order_id) as order_id,
        cast(payment_sequential as integer) as payment_sequential,
        lower(trim(payment_type)) as payment_type,
        cast(payment_installments as integer) as payment_installments,
        cast(payment_value as numeric) as payment_value, 
        loaded_ts_utc
    from raw_order_payments_stg
)

select *
from order_payments_stg_1