select
  id,
  username,
  email,
  password
from
  "user"
where
  id = $1