SET search_path TO olx;

-- R07: Find unread messages belonging to a conversation
CREATE INDEX idx_chat_messages_unread_thread
ON chat_messages (thread_id)
INCLUDE (sender_id)
WHERE is_read = FALSE;