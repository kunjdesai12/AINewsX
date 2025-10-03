// lib/models/chat_message.dart
/// Model representing a single chat message.
/// Supports user/AI distinction, timestamps, and optional extra data (e.g., articles).
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Map<String, dynamic>? extraData;  // e.g., {'articles': [...], 'summaries': [...]}

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.extraData,
  });

  /// Factory for creating from JSON (for persistence/serialization if needed).
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String? ?? '',
      isUser: json['isUser'] as bool? ?? false,
      timestamp: DateTime.parse(json['timestamp'] as String? ?? DateTime.now().toIso8601String()),
      extraData: json['extraData'] as Map<String, dynamic>?,
    );
  }

  /// Converts to JSON for API history.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      if (extraData != null) 'extraData': extraData,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ChatMessage &&
              runtimeType == other.runtimeType &&
              text == other.text &&
              isUser == other.isUser &&
              timestamp == other.timestamp;

  @override
  int get hashCode => text.hashCode ^ isUser.hashCode ^ timestamp.hashCode;
}