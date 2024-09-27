select
  id,
  image_id,
  author,
  likes,
  exists(select 1 from "like" where post_id = id and user_id = $1) as liked
from
  post
order by
  likes
desc