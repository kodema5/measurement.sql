create procedure put(
    a tag
)
as $$
begin
    if a.id is null then
        insert into tag (instrument, min_at, max_at, type, notes, data)
        values (
            a.instrument,
            a.min_at,
            a.max_at,
            a.type,
            a.notes,
            a.data
        );
    else
        update tag
        set
            instrument = a.instrument,
            min_at = a.min_at,
            max_at = a.max_at,
            type = a.type,
            notes = a.notes,
            data = a.data
        where id = a.id;
    end if;
end;
$$ language plpgsql;

