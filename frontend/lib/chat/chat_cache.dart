class ChatCache {
  ChatCache._privateConstructor();
  static final ChatCache instance = ChatCache._privateConstructor();

  final Map<String, List<Map<String, dynamic>>> _messages = {};

  List<Map<String, dynamic>> getMessages(String conversationId) {
    return _messages[conversationId] ?? [];
  }

  void setMessages(String conversationId, List<Map<String, dynamic>> messages) {
    _messages[conversationId] = messages;
  }

  void addMessage(String conversationId, Map<String, dynamic> message) {
    _messages.putIfAbsent(conversationId, () => []);
    _messages[conversationId]!.add(message);
  }

  void updateMessage(String conversationId, String id, Map<String, dynamic> newMsg) {
    final list = _messages[conversationId];
    if (list == null) return;
    final idx = list.indexWhere((m) => m['id'] == id);
    if (idx != -1) list[idx] = newMsg;
  }
}
