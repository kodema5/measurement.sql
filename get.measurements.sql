
create type get_measurements_t as (
    instrument instrument_t,
    min_at timestamp with time zone,
    max_at timestamp with time zone,

    tags tag_type_t[],
    tagged_only boolean
);


create function get_measurements_t (
    instrument instrument_t,
    min_at timestamp with time zone default to_timestamp('1970-01-01', 'yyyy-mm-dd'),
    max_at timestamp with time zone default current_timestamp,

    -- tagged = false -- not-tagged with tag_types
    -- tagged = true  -- only with tag_types
    tags tag_type_t[] default '{}', -- enum_range(null::tag_type_t),
    tagged_only boolean default false -- default, get measurement not-tagged
)
returns get_measurements_t
as $$
    select (instrument, min_at, max_at, tags, tagged_only)::get_measurements_t;
$$ language sql stable;


create function get (
    p get_measurements_t
)
returns setof measurement
as $$
    with
    -- measurement data over period
    measurement_data as (select * from measurements(
        instrument => p.instrument,
        min_at => p.min_at,
        max_at => p.max_at
    )),

    -- get tagged-data
    tagged_data as (
        select at
        from measurement_data
        inner join tags(
            instrument => p.instrument,
            min_at => p.min_at,
            max_at => p.max_at,
            types => p.tags
        ) tags
        on measurement_data.at between tags.min_at and tags.max_at
    )

    -- filter tagged-data
    select *
    from measurement_data
    where
    p.tagged_only and measurement_data.at in (select at from tagged_data)
    or
    not p.tagged_only and measurement_data.at not in (select at from tagged_data)
    ;
$$ language sql stable;
