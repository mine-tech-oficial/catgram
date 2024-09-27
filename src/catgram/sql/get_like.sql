select
  user_id,
  post_id
from
  "like"
where
  user_id = $1
  and post_id = $2