-- This generic test tests the assumption that the amount column of the orders model is always greater than 5.

{% test assert_column_greater_than_five(model, column_name) %}

select
    {{ column_name }}
from {{ model }}
where {{ column_name }} <= 5

{% endtest %}