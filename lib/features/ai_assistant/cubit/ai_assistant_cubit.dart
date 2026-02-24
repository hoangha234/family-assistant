import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/ai_response_model.dart';
import '../services/ai_service.dart';

// Re-export MessageModel for use in UI
export '../models/ai_response_model.dart';

part 'ai_assistant_state.dart';

class AiAssistantCubit extends Cubit<AiAssistantState> {
  final AIService _aiService;

  AiAssistantCubit({AIService? aiService})
      : _aiService = aiService ?? AIService(),
        super(AiAssistantInitial());

  /// Send a user message and get AI response
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Create user message
    final userMessage = MessageModel.user(message.trim());

    // Optimistically add user message and set loading
    final updatedMessages = [...state.messages, userMessage];
    emit(state.copyWith(
      messages: updatedMessages,
      isLoading: true,
      errorMessage: null,
    ));

    try {
      // Call AI service with conversation history
      final response = await _aiService.sendMessage(updatedMessages);

      // Create assistant message
      final assistantMessage = MessageModel.assistant(response);

      // Add assistant response to messages
      emit(state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
      ));
    } on AIServiceException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please try again.',
      ));
    }
  }

  /// Send a quick suggestion
  void sendSuggestion(String suggestion) {
    sendMessage(suggestion);
  }

  /// Clear error message
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }

  /// Clear all messages and start fresh
  void clearChat() {
    emit(AiAssistantInitial());
  }

  @override
  Future<void> close() {
    _aiService.dispose();
    return super.close();
  }
}
