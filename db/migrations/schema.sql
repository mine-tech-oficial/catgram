CREATE TABLE post (
  id bigint PRIMARY KEY,
  image_id text UNIQUE NOT NULL,
  author text NOT NULL,
  likes int NOT NULL
);

CREATE TABLE "user" (
  id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  username text UNIQUE NOT NULL,
  email text UNIQUE NOT NULL,
  password text NOT NULL
);

CREATE TABLE "session" (
  id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  created_at timestamp NOT NULL,
  expires_at timestamp NOT NULL,
  user_id bigint NOT NULL REFERENCES "user"(id)
);

CREATE TABLE "like" (
  user_id bigint NOT NULL REFERENCES "user"(id),
  post_id bigint NOT NULL REFERENCES post(id),
  PRIMARY KEY (user_id, post_id)
);