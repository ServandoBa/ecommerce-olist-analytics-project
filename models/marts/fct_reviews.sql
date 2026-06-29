with reviews as (
    select
        order_id,
        order_rev_sk,
        review_id,
        review_score,
        review_score_segment,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp,
        raw_reviews_count,
        distinct_reviews_count,
        first_review_date,
        last_review_date,
        last_review_answer_timestamp,
        days_between_first_and_last_reviews,
        review_response_days
    from {{ ref('int_orders_reviews') }}
),

orders as (
    select
        order_id,
        customer_id,
        order_purchase_timestamp
    from {{ ref('stg_orders') }}
),

customers as (
    select
        customer_id,
        customer_unique_id
    from {{ ref('stg_customers') }}
),

customer_dim as (
    select
        customer_unique_id
    from {{ ref('int_orders_customers') }}
)

select
    reviews.order_id,
    reviews.order_rev_sk,
    reviews.review_id,
    customer_dim.customer_unique_id,
    date(orders.order_purchase_timestamp) as order_date_key,
    reviews.review_score,
    reviews.review_score_segment,
    reviews.review_response_days as response_days,
    reviews.review_comment_title,
    reviews.review_comment_message,
    reviews.review_creation_date,
    reviews.review_answer_timestamp,
    reviews.raw_reviews_count,
    reviews.distinct_reviews_count,
    reviews.first_review_date,
    reviews.last_review_date,
    reviews.last_review_answer_timestamp,
    reviews.days_between_first_and_last_reviews,
    current_timestamp() as loaded_ts_utc
from reviews
left join orders
    on reviews.order_id = orders.order_id
left join customers
    on orders.customer_id = customers.customer_id
left join customer_dim
    on customers.customer_unique_id = customer_dim.customer_unique_id