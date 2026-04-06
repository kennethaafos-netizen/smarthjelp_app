class ChatMessage {
  final String id;
  final String jobId;
  final String senderId;
  final String text;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.jobId,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  ChatMessage copyWith({
    String? id,
    String? jobId,
    String? senderId,
    String? text,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}