with order_reviews as (
    select
        order_rev_sk,
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp,
        loaded_ts_utc
    from {{ ref('stg_order_reviews') }}
),

ranked_reviews as (
    select
        *,
        row_number() over (
            partition by order_id
            order by review_answer_timestamp desc, review_creation_date desc, review_id desc
        ) as review_rank
    from order_reviews
),

review_rollup as (
    select
        order_id,
        min(review_creation_date) as first_review_date,
        max(review_creation_date) as last_review_date,
        max(review_answer_timestamp) as last_review_answer_timestamp,
        count(*) as raw_reviews_count,
        count(distinct review_id) as distinct_reviews_count,
        max(loaded_ts_utc) as loaded_ts_utc,
        array_agg(
            struct(
                review_rank,
                order_rev_sk,
                review_id,
                review_score,
                review_comment_title,
                review_comment_message,
                review_creation_date,
                review_answer_timestamp,
                loaded_ts_utc
            )
            order by review_rank
        ) as all_reviews
    from ranked_reviews
    group by order_id
),

int_order_reviews_final as (
    select
        rr.order_rev_sk,
        rr.order_id,
        rr.review_id,
        rr.review_score,
        case
            when rr.review_score <= 2 then 'detractor'
            when rr.review_score = 3 then 'passive'
            else 'promoter'
        end as review_score_segment,
        rr.review_comment_title,
        rr.review_comment_message,
        rr.review_creation_date,
        rr.review_answer_timestamp,
        review_agg.raw_reviews_count,
        review_agg.distinct_reviews_count,
        review_agg.all_reviews,
        review_agg.first_review_date,
        review_agg.last_review_date,
        review_agg.last_review_answer_timestamp,
        timestamp_diff(review_agg.last_review_date, review_agg.first_review_date, day) as days_between_first_and_last_reviews,
        timestamp_diff(rr.review_answer_timestamp, rr.review_creation_date, day) as review_response_days,
        review_agg.loaded_ts_utc
    from ranked_reviews as rr
    left join review_rollup as review_agg
        on rr.order_id = review_agg.order_id
    where rr.review_rank = 1
)

select
    order_rev_sk,
    order_id,
    review_id,
    review_score,
    review_score_segment,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp,
    raw_reviews_count,
    distinct_reviews_count,
    all_reviews,
    first_review_date,
    last_review_date,
    last_review_answer_timestamp,
    days_between_first_and_last_reviews,
    review_response_days,
    loaded_ts_utc
from int_order_reviews_final