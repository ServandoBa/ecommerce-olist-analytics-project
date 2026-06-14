WITH raw_order_reviews_stg AS (
select 
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp,
    loaded_ts_utc
from {{ source ('raw_tables', 'raw_order_reviews') }} ),
order_order_reviews_stg_1 as (
    select 
        trim(review_id) as review_id,
        trim(order_id) as order_id,
        cast(review_score as int) as review_score,
        trim(review_comment_title) as review_comment_title,
        trim(review_comment_message) as review_comment_message,
        cast(review_creation_date as timestamp) as review_creation_date,
        cast(review_answer_timestamp as timestamp) as review_answer_timestamp,
        loaded_ts_utc
    from raw_order_reviews_stg
)

select *
from order_order_reviews_stg_1