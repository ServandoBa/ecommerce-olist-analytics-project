with order_reviews as (
    select
        order_rev_sk,
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp
    from {{ ref('stg_order_reviews') }}
),

ranked_reviews as (
    select
        *,
        row_number() over (
            partition by order_id
            order by
                review_answer_timestamp desc,
                review_creation_date desc,
                review_id desc
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
        array_agg(
            struct(
                review_rank,
                order_rev_sk,
                review_id,
                review_score,
                review_comment_title,
                review_comment_message,
                review_creation_date,
                review_answer_timestamp
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
        rollup.raw_reviews_count,
        rollup.distinct_reviews_count,
        rollup.all_reviews,
        rollup.first_review_date,
        rollup.last_review_date,
        rollup.last_review_answer_timestamp,
        timestamp_diff(rollup.last_review_date, rollup.first_review_date, day) as days_between_first_and_last_reviews,
        timestamp_diff(rr.review_answer_timestamp, rr.review_creation_date, day) as review_response_days
    from ranked_reviews as rr
    left join review_rollup as rollup
        on rr.order_id = rollup.order_id
    where rr.review_rank = 1
)

select *
from int_order_reviews_final