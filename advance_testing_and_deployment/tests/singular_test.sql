-- This singular test tests the assumption that the amount column of the orders model is always greater than 5.

select 
    amount 
from {{ ref('orders') }} 
where amount <= 5
