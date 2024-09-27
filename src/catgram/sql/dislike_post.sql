update
  post
set
  likes = likes - 1
where
  id = $1