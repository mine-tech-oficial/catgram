select
  id,
  username,
  email,
  password
from
  "user"
where
  username = $1