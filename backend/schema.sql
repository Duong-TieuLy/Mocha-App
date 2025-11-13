-- users minimal
CREATE TABLE IF NOT EXISTS users (
  id varchar PRIMARY KEY,
  username varchar NOT NULL UNIQUE,
  display_name varchar,
  avatar_url varchar,
  created_at timestamptz DEFAULT now()
);

-- conversations
CREATE TABLE IF NOT EXISTS conversations (
  id varchar PRIMARY KEY,
  is_group boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS participants (
  conversation_id varchar REFERENCES conversations(id),
  user_id varchar REFERENCES users(id),
  role varchar,
  PRIMARY KEY(conversation_id, user_id)
);

-- ✅ messages (đã thêm receiver_id)
CREATE TABLE IF NOT EXISTS messages (
  id varchar PRIMARY KEY,
  conversation_id varchar NOT NULL REFERENCES conversations(id),
  sender_id varchar NOT NULL REFERENCES users(id),
  receiver_id varchar REFERENCES users(id),
  content text,
  type varchar,
  attachment_url varchar,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_messages_conv_created ON messages(conversation_id, created_at);

-- message_status: per recipient
CREATE TABLE IF NOT EXISTS message_status (
  id serial PRIMARY KEY,
  message_id varchar REFERENCES messages(id),
  user_id varchar REFERENCES users(id),
  status varchar, -- sent, delivered, read
  updated_at timestamptz DEFAULT now()
);
