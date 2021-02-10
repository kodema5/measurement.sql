create function to_ts (
    t timestamp with time zone
) returns int as $$
    select trunc(extract(epoch from t))::int;
$$ language sql stable;
