import 'package:equatable/equatable.dart';

enum MessageRole { user, assistant }

class MessageModel extends Equatable {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;

  const MessageModel({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
  });

  /// Creates a user message
  factory MessageModel.user(String content) {
    return MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
  }

  /// Creates an assistant message
  factory MessageModel.assistant(String content) {
    return MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
    );
  }

  /// Convert to API format for multi-turn conversation
  Map<String, String> toApiFormat() {
    return {
      'role': role == MessageRole.user ? 'user' : 'assistant',
      'content': content,
    };
  }

  @override
  List<Object?> get props => [id, content, role, timestamp];
}
