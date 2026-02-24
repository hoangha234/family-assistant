import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/ai_response_model.dart';

/// Custom exception for AI service errors
class AIServiceException implements Exception {
  final String message;
  final int? statusCode;

  AIServiceException(this.message, {this.statusCode});

  @override
  String toString() => 'AIServiceException: $message';
}

/// Service to communicate with Google Gemini API
class AIService {
  final String _apiKey;
  String _model;
  final HttpClient _httpClient;

  DateTime? _lastRequestTime;
  static const _minRequestInterval = Duration(seconds: 1);

  bool _useFallback = false;
  static const List<String> _availableModels = [
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    'gemini-1.5-flash',
    'gemini-1.5-pro',
  ];

  // Try different API versions
  static const List<String> _apiVersions = ['v1beta', 'v1'];
  int _currentApiVersionIndex = 0;

  int _currentModelIndex = 0;

  AIService({
    String? apiKey,
    String? model,
  })  : _apiKey = apiKey ?? 'AIzaSyAtEUiABLBl4D8ygkNA214GcUVNlsDGt-E',
        _model = model ?? 'gemini-2.0-flash',
        _httpClient = HttpClient();

  String get _currentApiVersion => _apiVersions[_currentApiVersionIndex];

  /// 🔥 SYSTEM PROMPT (FIX NGỐ + CASUAL)
  static const String _systemPrompt = '''
You are a smart, friendly AI assistant inside a personal assistant mobile app.

You have TWO equally important modes:
1. App Assistant Mode:
- Help with finance, expenses, meals, health, shopping schedules, and IoT devices.
- Explain features clearly when asked.

2. Conversational Mode:
- Chat naturally about everyday topics.
- Respond to emotions, jokes, and casual conversation.
- You do NOT need to relate everything to the app.

Language rules:
- Always reply in the SAME language as the user's last message.
- Switch language immediately if the user switches.

Conversation rules:
- Assume multi-turn conversation.
- Do NOT repeat the user's message.
- Do NOT repeat your previous answers.
- Keep responses natural and human-like.

Personality:
- Warm, friendly, relaxed.
- Not robotic.
- Slightly casual when appropriate.

If unsure:
- Say you are unsure.
- Ask ONE short clarification question.

You are allowed to be conversational and informal when appropriate.
''';

  /// Send a message and get AI response
  Future<String> sendMessage(
    List<MessageModel> messages, {
    int retryCount = 0,
  }) async {
    if (_useFallback) {
      debugPrint('⚠️ [AI] Using fallback mode');
      return _getMockResponse(messages.last.content);
    }

    // Rate limiting
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - elapsed);
      }
    }
    _lastRequestTime = DateTime.now();

    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/$_currentApiVersion/models/$_model:generateContent?key=$_apiKey',
      );

      final request = await _httpClient.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');

      // 🔥 LIMIT CONTEXT (5–8 messages)
      final recentMessages = messages.length > 8
          ? messages.sublist(messages.length - 8)
          : messages;

      final contents = <Map<String, dynamic>>[];

      // 👉 System prompt (ONLY ONE user message, no model confirmation)
      contents.add({
        'role': 'user',
        'parts': [
          {'text': _systemPrompt}
        ]
      });

      // Conversation history
      for (final message in recentMessages) {
        contents.add({
          'role': message.role == MessageRole.user ? 'user' : 'model',
          'parts': [
            {'text': message.content}
          ]
        });
      }

      final body = jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': 0.8,
          'topP': 0.9,
          'maxOutputTokens': 800,
        },
      });

      request.write(body);

      // 🔍 DEBUG: Log request
      debugPrint('🔄 [AI] API: $_currentApiVersion | Model: $_model');
      debugPrint('🔄 [AI] Messages count: ${recentMessages.length}');

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      // 🔍 DEBUG: Log response status
      debugPrint('📥 [AI] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;

        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates.first['content'];
          final parts = content?['parts'] as List<dynamic>?;

          if (parts != null && parts.isNotEmpty) {
            final responseText = parts.first['text'] as String;
            debugPrint('✅ [AI] Got response: ${responseText.substring(0, responseText.length > 50 ? 50 : responseText.length)}...');
            return responseText;
          }
        }

        throw AIServiceException('Empty response from Gemini');
      }

      // 🔁 Retry with another model if not found
      if (response.statusCode == 404) {
        if (_currentModelIndex < _availableModels.length - 1) {
          debugPrint('⚠️ [AI] Model not found, trying next: ${_availableModels[_currentModelIndex + 1]}');
          _currentModelIndex++;
          _model = _availableModels[_currentModelIndex];
          return sendMessage(messages, retryCount: 0);
        } else if (_currentApiVersionIndex < _apiVersions.length - 1) {
          // Reset model index and try next API version
          debugPrint('⚠️ [AI] Trying API version: ${_apiVersions[_currentApiVersionIndex + 1]}');
          _currentModelIndex = 0;
          _model = _availableModels[0];
          _currentApiVersionIndex++;
          return sendMessage(messages, retryCount: 0);
        } else {
          // All models and API versions failed, use fallback
          debugPrint('❌ [AI] All models failed, using fallback');
          _useFallback = true;
          return _getMockResponse(messages.last.content);
        }
      }

      // 🔄 Retry on rate limit
      if ((response.statusCode == 429 || response.statusCode == 503) &&
          retryCount < 2) {
        debugPrint('⚠️ [AI] Rate limited, retrying in ${(retryCount + 1) * 3}s...');
        await Future.delayed(Duration(seconds: (retryCount + 1) * 3));
        return sendMessage(messages, retryCount: retryCount + 1);
      }

      // 🔻 Fallback cases
      if (response.statusCode == 401 ||
          response.statusCode == 403 ||
          response.statusCode == 429 ||
          response.statusCode == 503) {
        debugPrint('❌ [AI] Error ${response.statusCode}, switching to fallback');
        _useFallback = true;
        return _getMockResponse(messages.last.content);
      }

      debugPrint('❌ [AI] API Error: ${response.statusCode}');
      debugPrint('❌ [AI] Response: $responseBody');
      throw AIServiceException(
        'API error: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on SocketException {
      return _getMockResponse(messages.last.content);
    } catch (e) {
      if (e is AIServiceException) rethrow;
      return _getMockResponse(messages.last.content);
    }
  }

  /// Mock response cho demo / offline
  String _getMockResponse(String userMessage) {
    final isVietnamese = _isVietnamese(userMessage);

    if (isVietnamese) {
      return 'Mạng hơi có vấn đề 😅 nhưng tớ vẫn ở đây nè. Cậu nói tiếp đi~';
    } else {
      return 'Looks like the network is unstable 😅 but I\'m still here. Go on~';
    }
  }

  bool _isVietnamese(String text) {
    final vietnamesePattern = RegExp(
      r'[àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]',
      caseSensitive: false,
    );
    return vietnamesePattern.hasMatch(text);
  }

  void resetFallback() {
    _useFallback = false;
  }

  void dispose() {
    _httpClient.close();
  }
}
