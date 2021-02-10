create table measurement (
    instrument instrument_t,
    at timestamp with time zone,
    primary key (instrument, at),

    value value_t
);

create function measurement_t (
    instrument instrument_t,
    at timestamp with time zone default current_timestamp,
    value value_t default value_t()
)
returns measurement
as $$
    select (instrument, at, value):: measurement
$$ language sql stable;


create function measurements(
    instrument instrument_t,
    min_at timestamp with time zone default to_timestamp('1970-01-01', 'yyyy-mm-dd'),
    max_at timestamp with time zone default current_timestamp
)
returns setof measurement
as $$
    select *
    from measurement m
    where instrument = measurements.instrument
    and m.at between min_at and max_at
$$ language sql stable;
