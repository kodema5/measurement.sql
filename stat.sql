-- dynamically builds
-- value_stat_t holds statistics over multiple value_t
-- "stat" aggregate function for double precision fields
--

do $$
declare
    fields text[];
begin
    -- get fields
    select array_agg(attribute_name)
    into fields
    from (
        select attribute_name
        from information_schema.attributes
        where udt_schema = current_schema()
        and udt_name = 'value_t'
        and data_type = 'double precision'
        order by ordinal_position
    ) as foo;

    -- build value_stat_t
    execute format('create type value_stat_t as ( %s ) ',
        format_array(fields, '%I stat_t')
    );

    execute format('create function value_stat_t ( %s ) '
        'returns value_stat_t '
        'as $fn$ '
            'select ( %s ) :: value_stat_t'
        '$fn$ language sql stable',
        format_array(fields, '%I stat_t default stat_t()'),
        format_array(fields, '%I')
    );

    -- build aggregate step function
    execute format('create function step_ ( '
            's value_stat_t, '
            'x value_t '
        ') '
        'returns value_stat_t '
        'as $fn$ '
            'select value_stat_t(%s)'
        '$fn$ language sql stable',
        format_array(fields, 'step(s.%I, x.%I)')
    );

    -- step calls step_ with coalesce
    execute 'create function step ( '
            's value_stat_t, '
            'x value_t '
        ') '
        'returns value_stat_t '
        'as $fn$ '
            'select step_(coalesce(s, value_stat_t()),x) '
        '$fn$ language sql stable';

    -- build aggregate final function
    execute format('create function final (s value_stat_t) '
        'returns value_stat_t '
        'as $fn$ '
            'select value_stat_t(%s)'
        '$fn$ language sql stable',
        format_array(fields, 'final(s.%I)')
    );

    -- build aggregate function
    execute 'create aggregate stat (value_t) '
        '('
        '   stype = value_stat_t, '
        '   sfunc = step(value_stat_t), '
        '   finalfunc = final(value_stat_t) '
        ')';

end;
$$ language plpgsql;
