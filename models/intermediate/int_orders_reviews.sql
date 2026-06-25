with int_order_reviews as (
    select
        order_rev_sk,
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp,
        row_number() over(partition by order_id order by review_creation_date desc) rn
    from {{ ref('stg_order_reviews') }}  
),
int_order_reviews_1 as (
    select order_id,  
        min(review_creation_date) as first_review_date,
        max(review_creation_date) as last_review_date,
        count(distinct review_id) as reviews_count,
        ARRAY_AGG(
            STRUCT(rn, order_rev_sk, review_id, review_score, review_comment_title, review_comment_message, review_creation_date, review_answer_timestamp)
            ORDER BY review_creation_date DESC
            ) as all_reviews
    from int_order_reviews
    group by order_id
),
int_order_reviews_final as (
    select 
        orev.order_rev_sk,
        orev.order_id,
        orev.review_id,
        orev.review_score as last_review_score, 
        case when orev.review_score <= 2 then 'detractor'
            when orev.review_score = 3 then 'passive'
            else 'promoter'
        end as net_promoter_score, 
        orev1.reviews_count,
        orev1.all_reviews as agrupated_reviews_msg,
        orev1.first_review_date,
        orev1.last_review_date,
        date_diff(orev1.last_review_date, orev1.first_review_date, day) as days_between_first_and_last_reviews
    from int_order_reviews orev 
    left join int_order_reviews_1 orev1 on orev.order_id = orev1.order_id 
    where orev.rn=1
)

--pendiente terminar
select *
from int_order_reviews_final o



--inner join (select order_id, count(distinct review_id) from int_order_reviews group by order_id having count(distinct review_id)>1) c on o.order_id = c.order_id order by o.order_id, o.review_id

