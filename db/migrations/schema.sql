CREATE TABLE post (
  id int PRIMARY KEY,
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