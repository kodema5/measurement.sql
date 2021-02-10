create function table_name (
    m measurement
)
returns text
as $$
    select table_name(m.instrument, m.at)
$$ language sql stable;


create procedure put(
    m measurement
)
as $$
declare
    t_name text = table_name(m);
begin
    if not exists (
        select 1 from information_schema.tables
        where table_name = t_name
    ) then
        execute format (
            'create table %I ('
            '  primary key (instrument, at) '
            ') '
            'inherits (measurement)',
            t_name);
    end if;

    execute format (
        'insert into %I (instrument, at, value) '
        'values ($1, $2, $3) '
        'on conflict (instrument, at) '
        '   do update set value=$3'
        , t_name)
    using
        m.instrument,
        m.at,
        m.value;
end;
$$ language plpgsql;


create procedure put(
    measurements measurement[]
)
as $$
declare
    t_names text[];
    t_name text;
begin
    select array_agg(distinct m.table_name)
        into t_names
        from unnest(measurements) m;

    for i in 1..array_upper(t_names,1)
    loop
        t_name = t_names[i];

        if not exists (
            select 1 from information_schema.tables
            where table_name = t_name
        ) then
            execute format (
                'create table %I ('
                '  primary key (instrument, at) '
                ') '
                'inherits (measurement)',
                t_name);
        end if;

        execute format (
            'insert into %I (instrument, at, value) '
            '('
            '  select instrument, at, value '
            '  from unnest($1) l where  l.table_name=''%I'' '
            ') '
            '  on conflict (instrument, at) '
            '  do nothing' -- this can only be a do nothing
            , t_name, t_name)
            using
                measurements;
        end loop;
end;
$$ language plpgsql;

\if :test

    create function tests.test_put ()
    returns setof text
    as $$
    declare
        ms measurement[] = array[
            measurement_t('test_put', to_timestamp('1901-01-01', 'yyyy-mm-dd')),
            measurement_t('test_put', to_timestamp('1902-01-01', 'yyyy-mm-dd'))
        ]::measurement[];
        tn text;
    begin
        -- single
        call put(ms[1]);
        tn = ms[1].table_name;
        return next has_table(tn, 'has child table ' || tn);

        -- multiple
        call put(ms);
        tn = ms[1].table_name;
        return next has_table(tn, 'has child table ' || tn);
        tn = ms[2].table_name;
        return next has_table(tn, 'has child table ' || tn);
    end;
    $$ language plpgsql;

\endif