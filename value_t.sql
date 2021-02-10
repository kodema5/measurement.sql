-- create function value_t
--
do $$
declare
    a text;
    b text;
begin
    with fields as (
        select attribute_name, data_type
        from information_schema.attributes
        where udt_schema = current_schema()
        and udt_name = 'value_t'
        order by ordinal_position
    )
    select
        string_agg(format('%I %s default null', attribute_name, data_type),','),
        string_agg(format('%I', attribute_name),',')
    into a, b
    from fields;

    execute format(
        'create function value_t( %s ) '
        'returns value_t '
        'as $fn$ '
            'select (%s)::value_t '
        '$fn$ language sql stable'
        , a, b
    );
end;
$$ language plpgsql;
