insert into
  "session" (expires_at, user_id)
values
  ($1, $2)
returning
  id, date_trunc('second', created_at) as created_at