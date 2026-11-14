class ChatMessage {
  const ChatMessage({required this.text, required this.isUser, this.source});
  final String text;
  final bool isUser;

  /// Actual model or route that produced an assistant reply.
  final String? source;
}
