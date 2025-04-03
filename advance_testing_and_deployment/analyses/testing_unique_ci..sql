select
    customer_id as unique_field,
    count(*) as n_records

from ANALYTICS.CONSUMPTION.stg_jaffle_shop__orders
where customer_id is not null
group by customer_id
having count(*) > 1


