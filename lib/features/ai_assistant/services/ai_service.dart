import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../../core/config/api_keys.dart';
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
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
  ];

  // Try different API versions
  static const List<String> _apiVersions = ['v1beta', 'v1'];
  int _currentApiVersionIndex = 0;

  int _currentModelIndex = 0;

  AIService({
    String? apiKey,
    String? model,
  })  : _apiKey = apiKey ?? ApiKeys.geminiApiKey,
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

  // ============================================================
  // IMAGE GENERATION
  // ============================================================

  /// Generate an image from a text prompt using Gemini's image generation
  ///
  /// Tries multiple model configurations until one works
  /// Returns: Uint8List containing the image bytes, or null if all fail
  Future<Uint8List?> generateImage(String prompt) async {
    if (prompt.trim().isEmpty) {
      throw AIServiceException('Image prompt cannot be empty');
    }

    debugPrint('🎨 [AI] ========== IMAGE GENERATION START ==========');
    debugPrint('🎨 [AI] Prompt: ${prompt.substring(0, prompt.length > 80 ? 80 : prompt.length)}...');

    // Configuration attempts - try different models and settings
    final attempts = [
      // Attempt 1: gemini-2.0-flash-exp with IMAGE modality
      () => _tryGeminiImageGeneration(
        prompt: prompt,
        model: 'gemini-2.0-flash-exp',
        modalities: ['IMAGE'],
      ),
      // Attempt 2: gemini-2.0-flash-exp with IMAGE + TEXT
      () => _tryGeminiImageGeneration(
        prompt: prompt,
        model: 'gemini-2.0-flash-exp',
        modalities: ['IMAGE', 'TEXT'],
      ),
      // Attempt 3: Try imagen-3.0-generate-001
      () => _tryImagenGeneration(prompt: prompt, model: 'imagen-3.0-generate-001'),
      // Attempt 4: Try with different model name
      () => _tryGeminiImageGeneration(
        prompt: prompt,
        model: 'gemini-exp-1206',
        modalities: ['IMAGE'],
      ),
    ];

    for (int i = 0; i < attempts.length; i++) {
      debugPrint('🎨 [AI] --- Attempt ${i + 1}/${attempts.length} ---');
      try {
        final result = await attempts[i]();
        if (result != null && result.isNotEmpty) {
          debugPrint('✅ [AI] Image generated! Size: ${result.length} bytes');
          debugPrint('🎨 [AI] ========== IMAGE GENERATION SUCCESS ==========');
          return result;
        }
      } catch (e) {
        debugPrint('⚠️ [AI] Attempt ${i + 1} exception: $e');
      }
    }

    debugPrint('❌ [AI] All attempts failed');
    debugPrint('🎨 [AI] ========== IMAGE GENERATION FAILED ==========');
    return null;
  }

  /// Try Gemini model for image generation
  Future<Uint8List?> _tryGeminiImageGeneration({
    required String prompt,
    required String model,
    required List<String> modalities,
  }) async {
    debugPrint('🎨 [AI] Model: $model, Modalities: $modalities');

    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey',
      );

      final request = await _httpClient.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');

      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': 'Create a professional, appetizing food photograph of: $prompt. '
                    'Style: high-quality food photography, well-lit, beautiful plating, shallow depth of field.'
              }
            ]
          }
        ],
        'generationConfig': {
          'responseModalities': modalities,
        },
      });

      request.write(body);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      debugPrint('🎨 [AI] HTTP Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;

        // Debug: log structure
        _debugLogResponse(data);

        return _extractImageFromResponse(data);
      } else {
        _debugLogError(responseBody);
      }

      return null;
    } catch (e) {
      debugPrint('❌ [AI] Gemini error: $e');
      return null;
    }
  }

  /// Try Imagen model for image generation
  Future<Uint8List?> _tryImagenGeneration({
    required String prompt,
    required String model,
  }) async {
    debugPrint('🎨 [AI] Imagen Model: $model');

    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:predict?key=$_apiKey',
      );

      final request = await _httpClient.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');

      final body = jsonEncode({
        'instances': [
          {'prompt': 'Professional food photography: $prompt'}
        ],
        'parameters': {
          'sampleCount': 1,
          'aspectRatio': '4:3',
        },
      });

      request.write(body);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      debugPrint('🎨 [AI] HTTP Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        return _extractImageFromImagenResponse(data);
      } else {
        _debugLogError(responseBody);
      }

      return null;
    } catch (e) {
      debugPrint('❌ [AI] Imagen error: $e');
      return null;
    }
  }

  /// Debug log response structure
  void _debugLogResponse(Map<String, dynamic> data) {
    try {
      debugPrint('🔍 [AI] Response keys: ${data.keys.toList()}');

      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        debugPrint('🔍 [AI] No candidates found');
        return;
      }

      debugPrint('🔍 [AI] Candidates count: ${candidates.length}');

      final firstCandidate = candidates.first as Map<String, dynamic>;
      final content = firstCandidate['content'] as Map<String, dynamic>?;

      if (content == null) {
        debugPrint('🔍 [AI] No content in first candidate');
        return;
      }

      final parts = content['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        debugPrint('🔍 [AI] No parts in content');
        return;
      }

      debugPrint('🔍 [AI] Parts count: ${parts.length}');

      for (int i = 0; i < parts.length; i++) {
        final part = parts[i] as Map<String, dynamic>;
        debugPrint('🔍 [AI] Part $i keys: ${part.keys.toList()}');

        if (part.containsKey('text')) {
          final text = part['text'] as String;
          debugPrint('🔍 [AI] Part $i has text (${text.length} chars)');
        }
        if (part.containsKey('inline_data')) {
          final inlineData = part['inline_data'] as Map<String, dynamic>;
          debugPrint('🔍 [AI] Part $i has inline_data: ${inlineData.keys.toList()}');
          if (inlineData.containsKey('mime_type')) {
            debugPrint('🔍 [AI] MIME type: ${inlineData['mime_type']}');
          }
          if (inlineData.containsKey('data')) {
            final dataStr = inlineData['data'] as String;
            debugPrint('🔍 [AI] Data length: ${dataStr.length} chars');
          }
        }
      }
    } catch (e) {
      debugPrint('🔍 [AI] Debug log error: $e');
    }
  }

  /// Debug log error response
  void _debugLogError(String responseBody) {
    try {
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final error = data['error'] as Map<String, dynamic>?;
      if (error != null) {
        debugPrint('❌ [AI] Error code: ${error['code']}');
        debugPrint('❌ [AI] Error message: ${error['message']}');
        debugPrint('❌ [AI] Error status: ${error['status']}');
      } else {
        debugPrint('❌ [AI] Unknown error format');
      }
    } catch (_) {
      debugPrint('❌ [AI] Raw error: ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}');
    }
  }

  /// Extract base64 image data from Gemini response
  Uint8List? _extractImageFromResponse(Map<String, dynamic> data) {
    try {
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        debugPrint('❌ [AI] No candidates in image response');
        return null;
      }

      final content = candidates.first['content'] as Map<String, dynamic>?;
      if (content == null) {
        debugPrint('❌ [AI] No content in image response');
        return null;
      }

      final parts = content['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        debugPrint('❌ [AI] No parts in image response');
        return null;
      }

      // Look for inline_data with image
      for (final part in parts) {
        if (part is Map<String, dynamic>) {
          final inlineData = part['inline_data'] as Map<String, dynamic>?;
          if (inlineData != null) {
            final mimeType = inlineData['mime_type'] as String?;
            final base64Data = inlineData['data'] as String?;

            if (base64Data != null && mimeType?.startsWith('image/') == true) {
              debugPrint('✅ [AI] Found image data, mime: $mimeType');
              return base64Decode(base64Data);
            }
          }

          // Also check for fileData
          final fileData = part['file_data'] as Map<String, dynamic>?;
          if (fileData != null) {
            debugPrint('✅ [AI] Found file_data in response');
            // File data contains a URI, would need additional fetch
          }
        }
      }

      debugPrint('❌ [AI] No image data found in response parts');
      return null;
    } catch (e) {
      debugPrint('❌ [AI] Error extracting image: $e');
      return null;
    }
  }

  /// Extract base64 image from Imagen response format
  Uint8List? _extractImageFromImagenResponse(Map<String, dynamic> data) {
    try {
      final predictions = data['predictions'] as List<dynamic>?;
      if (predictions == null || predictions.isEmpty) {
        debugPrint('❌ [AI] No predictions in Imagen response');
        return null;
      }

      final prediction = predictions.first as Map<String, dynamic>;
      final bytesBase64 = prediction['bytesBase64Encoded'] as String?;

      if (bytesBase64 != null) {
        debugPrint('✅ [AI] Found Imagen image data');
        return base64Decode(bytesBase64);
      }

      debugPrint('❌ [AI] No bytesBase64Encoded in Imagen response');
      return null;
    } catch (e) {
      debugPrint('❌ [AI] Error extracting Imagen image: $e');
      return null;
    }
  }

  void resetFallback() {
    _useFallback = false;
  }

  /// Send a message with an image attachment for analysis (food scanning, etc.)
  Future<String> sendMessageWithImage(
    List<MessageModel> messages,
    String base64Image, {
    int retryCount = 0,
  }) async {
    if (_useFallback) {
      debugPrint('⚠️ [AI] Using fallback mode for image analysis');
      return _getMockFoodAnalysisResponse();
    }

    // Rate limiting
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - elapsed);
      }
    }
    _lastRequestTime = DateTime.now();

    // Vision-capable models to try - using same model that works for chat
    final visionModels = [
      'gemini-2.0-flash',        // Current working model for chat
      'gemini-2.0-flash-exp',    // Experimental with vision
      'gemini-1.5-flash',
      'gemini-pro-vision',
    ];

    // API versions to try
    final apiVersions = ['v1beta', 'v1'];

    final prompt = messages.isNotEmpty ? messages.last.content : 'Analyze this image';

    for (final apiVersion in apiVersions) {
      for (final visionModel in visionModels) {
        try {
          debugPrint('🔄 [AI] Trying $visionModel with API $apiVersion...');

          final uri = Uri.parse(
            'https://generativelanguage.googleapis.com/$apiVersion/models/$visionModel:generateContent?key=$_apiKey',
          );

          final request = await _httpClient.postUrl(uri);
          request.headers.set('Content-Type', 'application/json');

          final body = jsonEncode({
            'contents': [
              {
                'parts': [
                  {
                    'text': prompt,
                  },
                  {
                    'inline_data': {
                      'mime_type': 'image/jpeg',
                      'data': base64Image,
                    }
                  }
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.4,
              'topP': 0.8,
              'maxOutputTokens': 500,
            },
          });

          request.write(body);

          final response = await request.close();
          final responseBody = await response.transform(utf8.decoder).join();

          debugPrint('📥 [AI] $visionModel/$apiVersion status: ${response.statusCode}');

          if (response.statusCode == 200) {
            final data = jsonDecode(responseBody) as Map<String, dynamic>;
            final candidates = data['candidates'] as List<dynamic>?;

            if (candidates != null && candidates.isNotEmpty) {
              final content = candidates.first['content'];
              final parts = content?['parts'] as List<dynamic>?;

              if (parts != null && parts.isNotEmpty) {
                final responseText = parts.first['text'] as String;
                debugPrint('✅ [AI] Image analysis complete with $visionModel/$apiVersion');
                return responseText;
              }
            }
          }

          // Log error details for debugging
          if (response.statusCode != 200) {
            debugPrint('⚠️ [AI] $visionModel/$apiVersion failed: ${response.statusCode}');
            // Try to get error message
            try {
              final errorData = jsonDecode(responseBody);
              debugPrint('⚠️ [AI] Error: ${errorData['error']?['message'] ?? responseBody}');
            } catch (_) {}
          }

        } catch (e) {
          debugPrint('❌ [AI] Exception with $visionModel/$apiVersion: $e');
        }
      }
    }

    // All models failed, return mock
    debugPrint('❌ [AI] All vision models failed, using fallback');
    return _getMockFoodAnalysisResponse();
  }


  /// Mock food analysis response for fallback
  String _getMockFoodAnalysisResponse() {
    return '''
{
  "food_name": "Mixed Meal",
  "calories": 450,
  "protein": 25,
  "carbs": 45,
  "fat": 18
}
''';
  }

  /// Analyze an image (for food scanning) and return structured JSON
  Future<String> analyzeImage(String base64Image) async {
    const prompt = '''Analyze this food image and estimate the nutritional information.
Return ONLY a valid JSON object with no additional text or markdown:
{
  "food_name": "name of the food",
  "calories": estimated calories as integer,
  "protein": protein in grams as integer,
  "carbs": carbohydrates in grams as integer,
  "fat": fat in grams as integer
}

Be realistic with your estimates based on typical serving sizes.
If you cannot identify the food, make your best guess based on what you see.''';

    final messages = [
      MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: prompt,
        role: MessageRole.user,
        timestamp: DateTime.now(),
      ),
    ];

    return sendMessageWithImage(messages, base64Image);
  }  void dispose() {
    _httpClient.close();
  }
}
