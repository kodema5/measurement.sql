create type periodicity_t as enum (
    'hourly',
    'daily',
    'weekly',
    'quarterly',
    'monthly',
    'yearly'
);

create function to_period(
    p periodicity_t,
    at timestamp with time zone
)
returns text
as $$
    select
    case
    when p = 'hourly' then to_char(at, 'yyyy_mm_dd_hh24')
    when p = 'daily' then to_char(at, 'yyyy_mm_dd')
    when p = 'weekly' then to_char(at, 'iyyy_iw')
    when p = 'monthly' then to_char(at, 'yyyy_mm')
    when p = 'quarterly' then to_char(at, 'yyyy_q')
    when p = 'yearly' then to_char(at, 'yyyy')
    else null
    end as period;
$$ language sql stable;


create function to_timestamp(
    p periodicity_t,
    at text
)
returns timestamp with time zone
as $$
    select
    case
    when p = 'hourly' then to_timestamp(at, 'yyyy_mm_dd_hh24')
    when p = 'daily' then to_timestamp(at, 'yyyy_mm_dd')
    when p = 'weekly' then to_timestamp(at, 'iyyy_iw')
    when p = 'monthly' then to_timestamp(at, 'yyyy_mm')
    when p = 'quarterly' then format('%s-%s-1', left(at, 4), right(at, 1)::int* 3- 2)::timestamp
    when p = 'yearly' then to_timestamp(at, 'yyyy')
    else null
    end;
$$ language sql stable;


create type get_periodic_measurements_t as (
    instrument instrument_t,
    min_at timestamp with time zone,
    max_at timestamp with time zone,

    tags tag_type_t[],
    tagged_only boolean,

    periodicity periodicity_t
);

create function get_periodic_measurements_t (
    instrument instrument_t,
    min_at timestamp with time zone default to_timestamp('1970-01-01', 'yyyy-mm-dd'),
    max_at timestamp with time zone default current_timestamp,

    tags tag_type_t[] default '{}', -- enum_range(null::tag_type_t),
    tagged_only boolean default false, -- default, get measurement not-tagged

    periodicity periodicity_t default 'hourly'
)
returns get_periodic_measurements_t
as $$
    select (
        instrument, min_at, max_at,
        tags, tagged_only,
        periodicity
    )::get_periodic_measurements_t;
$$ language sql stable;



create function get(
    p get_periodic_measurements_t
) returns table (
    instrument instrument_t,
    period text,
    at timestamp with time zone,
    stat value_stat_t
)
as $$
    select
        instrument,
        period,
        to_timestamp(p.periodicity, period),
        stat(value) as stat
    from (
        select
        to_period(p.periodicity, at) as period,
        *
        from get(get_measurements_t(
            instrument:=p.instrument,
            min_at:=p.min_at,
            max_at:=p.max_at,
            tags:=p.tags,
            tagged_only:=p.tagged_only
        ))
    ) as ms
    group by instrument, period
    order by instrument, period
$$ language sql stable;

