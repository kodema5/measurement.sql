
-- define instrument
--
create domain instrument_t as text not null;


-- an example value to store
-- value_stat_t will be derived from double-precision fields
--
create type value_t as (
    x double precision,
    y double precision
);

-- type of tags
--
create type tag_type_t as enum (
    'error'
);


-- how to partition measurement data
--
create function table_name (
    id instrument_t,
    at timestamp with time zone
)
returns text
as $$
    select format('measurement__%I__%s', id, extract('year' from at))
$$ language sql stable;


