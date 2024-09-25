select
  id,
  date_trunc('second', created_at) as created_at,
  expires_at,
  user_id
from
  "session"
where
  id = $1