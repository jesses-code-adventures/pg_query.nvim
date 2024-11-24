-- name: GetPeople :many
with people as (
    select * from person
    where id = $1
    and from_party_id = $2
    and to_party_id = $3
)
select * from users;
