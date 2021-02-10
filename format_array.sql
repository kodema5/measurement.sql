create function format_array (
    arr text[],
    fmt text default '%I'

) returns text as $$
    select string_agg(b.b, ',')
    from (
        select format(fmt, a, a, a) b
        from unnest(arr) as a
    ) b
$$ language sql;
