with date_spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2016-01-01' as date)",
        end_date="cast('2019-01-01' as date)"
    ) }}
),

dim_date as (
    select
        date_day,
        extract(year from date_day) as year,
        extract(quarter from date_day) as quarter,
        extract(month from date_day) as month,
        format_date('%B', date_day) as month_name,
        extract(day from date_day) as day,
        mod(extract(dayofweek from date_day) + 5, 7) + 1 as day_of_week,
        format_date('%A', date_day) as day_name,
        extract(week from date_day) as week_of_year,
        case when extract(dayofweek from date_day) in (1, 7) then 1 else 0 end as is_weekend
    from date_spine
)

select
    date_day,
    year,
    quarter,
    month,
    month_name,
    day,
    day_of_week,
    day_name,
    week_of_year,
    is_weekend,
    current_timestamp() as loaded_ts_utc
from dim_date