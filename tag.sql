
create function first_tag_type () returns tag_type_t as $$
    select (enum_range(null::tag_type_t))[1]
$$ language sql stable;


create table tag (
    instrument instrument_t not null,
    min_at timestamp with time zone,
    max_at timestamp with time zone,
    type tag_type_t,
    notes text,
    data jsonb,
    id serial
);


create function tag_t (
    instrument instrument_t,
    min_at timestamp with time zone,
    max_at timestamp with time zone,

    type tag_type_t default first_tag_type(),
    notes text default null,
    data jsonb default null,
    id int default null
) returns tag as $$
    select (instrument, min_at, max_at, type, notes, data, id)::tag
$$ language sql stable;


create function tags (
    instrument instrument_t,
    min_at timestamp with time zone default to_timestamp('1970-01-01', 'yyyy-mm-dd'),
    max_at timestamp with time zone default current_timestamp,
    types tag_type_t[] default enum_range(null::tag_type_t)
)
returns setof tag
as $$
    select *
    from tag t
    where instrument = tags.instrument
    and (
        -- crossed left
        t.min_at between tags.min_at and tags.max_at
        -- in between
        or t.min_at <= tags.min_at and t.max_at >= tags.max_at
        -- crossed right
        or t.max_at between tags.min_at and tags.max_at
    )
    and type = any(types)
$$ language sql stable;
