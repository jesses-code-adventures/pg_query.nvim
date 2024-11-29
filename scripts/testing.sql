-- name: GetUsers :many
with users as (
    select * from users
    where id = $1
)
select * from users;

select * from users where id = $1 and name = $2;
