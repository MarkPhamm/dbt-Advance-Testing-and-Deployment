{% test not_null(model, column_name, column_id ) %}

select *
from {{ model }}
where {{ column_name }} is null
and {{ column_id }} is not in ('00000') -- modify

{% endtest %}