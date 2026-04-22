class ChatMessage {
  final String id;
  final String jobId;
  // NB: 'system' som magic-verdi beholdes for UI-kompatibilitet.
  // I Supabase mappes det til NULL i kolonnen sender_id.
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

  bool get isSystem => senderId == 'system';

  // ---------------- SUPABASE ----------------

  factory ChatMessage.fromSupabase(Map<String, dynamic> map) {
    final rawSender = map['sender_id'];
    final senderId = rawSender == null || rawSender.toString().isEmpty
        ? 'system'
        : rawSender.toString();

    return ChatMessage(
      id: (map['id'] ?? '').toString(),
      jobId: (map['job_id'] ?? '').toString(),
      senderId: senderId,
      text: (map['text'] ?? '').toString(),
      createdAt: _toDateTime(map['created_at']) ?? DateTime.now(),
      replyToMessageId: _nullableString(map['reply_to_message_id']),
      replyToText: _nullableString(map['reply_to_text']),
      imageUrl: _nullableString(map['image_url']),
      reaction: _nullableString(map['reaction']),
    );
  }

  Map<String, dynamic> toSupabaseInsert() {
    return {
      'id': id,
      'job_id': jobId,
      'sender_id': senderId == 'system' ? null : senderId,
      'text': text,
      'image_url': imageUrl,
      'reply_to_message_id': replyToMessageId,
      'reply_to_text': replyToText,
      'reaction': reaction,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ---------------- INTERNAL ----------------

  static const _sentinel = Object();

  static String? _nullableString(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    final parsed = DateTime.tryParse(value.toString());
    return parsed?.toLocal();
  }
}
