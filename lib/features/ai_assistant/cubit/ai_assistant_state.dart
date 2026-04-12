part of 'ai_assistant_cubit.dart';

/// Base state class for AI Assistant
class AiAssistantState extends Equatable {
  final List<MessageModel> messages;
  final bool isLoading;
  final String? errorMessage;

  const AiAssistantState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  /// Copy with method for immutable state updates
  AiAssistantState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AiAssistantState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, errorMessage];
}

/// Initial state with welcome message
class AiAssistantInitial extends AiAssistantState {
  AiAssistantInitial()
      : super(
          messages: [
            MessageModel.assistant(
              "Hello! I'm iMate, your personal assistant. How can I help you today?",
            ),
          ],
        );
}
