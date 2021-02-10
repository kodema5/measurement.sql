-- calculates statistic in one pass
--
create type stat_t as (
    count int,
    sum double precision,
    mean double precision,
    m2 double precision,
    var double precision,
    std double precision,
    first double precision,
    last double precision,
    min double precision,
    max double precision
);

create function stat_t (
    count int default 0,
    sum double precision  default 0.0,
    mean double precision  default 0.0,
    m2 double precision  default 0.0,
    var double precision default null,
    std double precision default null,
    first double precision default null,
    last double precision default null,
    min double precision default null,
    max double precision default null
) returns stat_t as $$
    select (
        count, sum, mean, m2,
        var, std,
        first, last,
        min, max
    )::stat_t
$$ language sql;

-- https://en.wikipedia.org/wiki/Algorithms_for_calculating_variance
-- implements welford's one-pass algorithm
--
create function step (
    s stat_t,
    x double precision
)
returns stat_t
as $$
declare
    a stat_t = coalesce(s, stat_t());
    d double precision = x - a.mean;
begin
    a.count = a.count + 1;
    a.sum = a.sum + x;
    a.mean = a.mean + d / a.count::float;
    a.m2 = a.m2 + d * (x - a.mean);

    a.first = coalesce(a.first, x);
    a.last = x;
    a.min = least(a.min, x);
    a.max = greatest(a.max, x);

    return a;
end;
$$ language plpgsql stable;


create function final (s stat_t)
returns stat_t
as $$
begin
    if s.count > 1 then
        s.var = s.m2 / (s.count - 1);
        s.std = sqrt(s.var);
    end if;
    return s;
end;
$$ language plpgsql stable;


create aggregate stat (double precision)
(
    stype = stat_t,
    sfunc = step (stat_t),
    finalfunc = final(stat_t)
);
