import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Exception for Vertex AI service errors
class VertexAIServiceException implements Exception {
  final String message;
  final int? statusCode;

  VertexAIServiceException(this.message, {this.statusCode});

  @override
  String toString() => 'VertexAIServiceException: $message';
}

/// Service to call Firebase Cloud Functions for Vertex AI
///
/// This service calls Cloud Functions which use Vertex AI:
/// - generateMealText: Uses Gemini for recipe generation
/// - generateMealImage: Uses Imagen for food image generation
///
/// Architecture:
/// Flutter App → Cloud Functions → Vertex AI
///
/// Benefits:
/// - No API keys in Flutter code
/// - Uses default service account authentication
/// - Secure and scalable
class VertexAIService {
/// Base URL for Cloud Functions
  /// These are the deployed Cloud Run URLs
  static const String _textFunctionUrl =
      'https://generatemealtext-fcsx3vx77a-uc.a.run.app';
  static const String _imageFunctionUrl =
      'https://generatemealimage-fcsx3vx77a-uc.a.run.app';
  static const String _healthCheckUrl =
      'https://healthcheck-fcsx3vx77a-uc.a.run.app';

  final http.Client _httpClient;

  VertexAIService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Generate meal recipe text using Gemini via Cloud Functions
  ///
  /// [prompt] - The recipe generation prompt
  /// [maxTokens] - Maximum tokens to generate (default: 1024)
  ///
  /// Returns: JSON string with recipe data
  Future<String> generateMealText(String prompt, {int maxTokens = 1024}) async {
    if (prompt.trim().isEmpty) {
      throw VertexAIServiceException('Prompt cannot be empty');
    }

    debugPrint('🤖 [VertexAI] Generating text...');
    debugPrint('🤖 [VertexAI] Prompt: ${prompt.substring(0, prompt.length > 50 ? 50 : prompt.length)}...');

    try {
      final response = await _httpClient.post(
        Uri.parse(_textFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'prompt': prompt,
          'maxTokens': maxTokens,
        }),
      );

      debugPrint('🤖 [VertexAI] Text response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true && data['text'] != null) {
          debugPrint('✅ [VertexAI] Text generated successfully');
          return data['text'] as String;
        } else {
          final errorMsg = data['error'] as String? ?? 'Unknown error';
          debugPrint('❌ [VertexAI] API returned error: $errorMsg');
          throw VertexAIServiceException(errorMsg);
        }
      } else {
        // Try to parse error from response body
        String errorMsg = 'HTTP ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          errorMsg = errorData['error'] as String? ?? errorMsg;
        } catch (_) {
          // If can't parse, use status code
          debugPrint('❌ [VertexAI] Raw response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        }
        debugPrint('❌ [VertexAI] Error: $errorMsg');
        throw VertexAIServiceException(
          errorMsg,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is VertexAIServiceException) rethrow;
      debugPrint('❌ [VertexAI] Text generation error: $e');
      throw VertexAIServiceException('Failed to generate text: $e');
    }
  }

  /// Generate meal image using Imagen via Cloud Functions
  ///
  /// [prompt] - The image generation prompt
  ///
  /// Returns: Uint8List containing the image bytes
  Future<Uint8List?> generateMealImage(String prompt) async {
    if (prompt.trim().isEmpty) {
      throw VertexAIServiceException('Prompt cannot be empty');
    }

    debugPrint('🎨 [VertexAI] Generating image...');
    debugPrint('🎨 [VertexAI] Prompt: ${prompt.substring(0, prompt.length > 50 ? 50 : prompt.length)}...');

    try {
      final response = await _httpClient.post(
        Uri.parse(_imageFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'prompt': prompt,
        }),
      );

      debugPrint('🎨 [VertexAI] Image response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true && data['image'] != null) {
          final base64Image = data['image'] as String;
          debugPrint('✅ [VertexAI] Image generated: ${base64Image.length} chars');
          return base64Decode(base64Image);
        } else {
          debugPrint('⚠️ [VertexAI] Image generation failed: ${data['error']}');
          return null;
        }
      } else {
        debugPrint('❌ [VertexAI] Image HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [VertexAI] Image generation error: $e');
      return null;
    }
  }

  /// Health check to verify Cloud Functions are running
  Future<bool> healthCheck() async {
    try {
      final response = await _httpClient.get(
        Uri.parse(_healthCheckUrl),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ [VertexAI] Health check: ${data['status']}');
        return data['status'] == 'ok';
      }
      return false;
    } catch (e) {
      debugPrint('❌ [VertexAI] Health check failed: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}

