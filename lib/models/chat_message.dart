class ChatMessage {
  final String id;
  final String jobId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final String? replyToMessageId;
  final String? replyToText;
  final String? imageUrl;
  final String? reaction;

  const ChatMessage({
    required this.id,
    required this.jobId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.replyToMessageId,
    this.replyToText,
    this.imageUrl,
    this.reaction,
  });

  ChatMessage copyWith({
    String? id,
    String? jobId,
    String? senderId,
    String? text,
    DateTime? createdAt,
    Object? replyToMessageId = _sentinel,
    Object? replyToText = _sentinel,
    Object? imageUrl = _sentinel,
    Object? reaction = _sentinel,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      replyToMessageId: replyToMessageId == _sentinel
          ? this.replyToMessageId
          : replyToMessageId as String?,
      replyToText: replyToText == _sentinel
          ? this.replyToText
          : replyToText as String?,
      imageUrl: imageUrl == _sentinel ? this.imageUrl : imageUrl as String?,
      reaction: reaction == _sentinel ? this.reaction : reaction as String?,
    );
  }

  static const _sentinel = Object();
}