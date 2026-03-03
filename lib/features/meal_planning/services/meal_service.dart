import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/meal_model.dart';
import '../../ai_assistant/services/ai_service.dart';
import '../../ai_assistant/models/ai_response_model.dart';
import 'vertex_ai_service.dart';

/// Exception for Meal Service errors
class MealServiceException implements Exception {
  final String message;
  MealServiceException(this.message);

  @override
  String toString() => 'MealServiceException: $message';
}

/// Service for meal planning operations
///
/// Supports two modes:
/// 1. Direct API (using AIService with API key) - default
/// 2. Vertex AI via Cloud Functions (more secure, no API key in app)
///
/// Set [useVertexAI] to true to use Cloud Functions
class MealService {
  final AIService _aiService;
  final VertexAIService _vertexAIService;
  final bool useVertexAI;

  MealService({
    AIService? aiService,
    VertexAIService? vertexAIService,
    this.useVertexAI = true, // Use Vertex AI Cloud Functions to avoid rate limits
  })  : _aiService = aiService ?? AIService(),
        _vertexAIService = vertexAIService ?? VertexAIService();

  /// System prompt for AI meal generation
  static const String _mealGenerationPrompt = '''
You are a professional nutritionist and chef AI assistant.
Your task is to generate a healthy meal recipe based on the ingredients provided by the user.

STRICT RULES:
1. Use primarily the ingredients provided by the user.
2. You may add minimal common pantry items (salt, oil, pepper, water, basic spices).
3. Nutrition values (calories, protein, carbs, fats) must be realistic and accurate.
4. The image_prompt must describe a professional food photograph suitable for a recipe app.
5. Instructions should be clear, numbered steps.
6. Ingredients list should include quantities.

OUTPUT FORMAT:
You MUST return ONLY valid JSON in this exact format, with no additional text, markdown, or explanation:

{
  "name": "Meal Name Here",
  "description": "A brief appetizing description of the dish in 1-2 sentences.",
  "calories": 450,
  "protein": 35,
  "carbs": 25,
  "fats": 18,
  "ingredients": [
    "400g chicken breast",
    "2 tablespoons olive oil",
    "1 teaspoon salt"
  ],
  "instructions": [
    "Preheat oven to 200°C.",
    "Season chicken with salt and pepper.",
    "Cook for 25 minutes until golden."
  ],
  "image_prompt": "Professional food photography of [dish name], beautifully plated, natural lighting, shallow depth of field"
}

IMPORTANT:
- Return ONLY the JSON object, nothing else.
- Do NOT wrap in markdown code blocks.
- Do NOT add any explanation before or after.
- Ensure all JSON is properly formatted and valid.
''';

  /// Generate a meal suggestion from AI based on ingredients
  Future<MealModel> generateMealFromAI(String ingredients, {MealType? mealType}) async {
    if (ingredients.trim().isEmpty) {
      throw MealServiceException('Please provide some ingredients');
    }

    try {
      // Try Vertex AI via Cloud Functions first
      if (useVertexAI) {
        try {
          return await _generateMealViaVertexAI(ingredients, mealType);
        } catch (e) {
          debugPrint('[MealService] Vertex AI failed: $e');
          debugPrint('[MealService] Falling back to Direct API...');
          // Fallback to direct API
          return await _generateMealViaDirectAPI(ingredients, mealType);
        }
      }

      // Otherwise use direct API
      return await _generateMealViaDirectAPI(ingredients, mealType);
    } catch (e) {
      debugPrint('[MealService] Error: $e');
      // If parsing fails, return a fallback meal
      if (e.toString().contains('parse') || e.toString().contains('JSON')) {
        return _generateFallbackMeal(ingredients, mealType);
      }
      if (e is MealServiceException) rethrow;
      throw MealServiceException('Failed to generate meal: $e');
    }
  }

  /// Generate meal using Vertex AI via Cloud Functions
  Future<MealModel> _generateMealViaVertexAI(String ingredients, MealType? mealType) async {
    debugPrint('[MealService] Using Vertex AI via Cloud Functions...');

    // Step 1: Generate recipe text
    final prompt = 'Create a healthy ${mealType?.displayName ?? "meal"} recipe using these ingredients: $ingredients';
    final response = await _vertexAIService.generateMealText(prompt);

    // Parse JSON response
    final mealJson = _parseJsonResponse(response);

    // Step 2: Generate image
    Uint8List? imageBytes;
    String? imagePrompt = mealJson['image_prompt'] as String?;

    if (imagePrompt != null && imagePrompt.isNotEmpty) {
      debugPrint('[MealService] Generating image via Vertex AI...');
      imageBytes = await _vertexAIService.generateMealImage(imagePrompt);

      if (imageBytes != null) {
        debugPrint('[MealService] Image generated: ${imageBytes.length} bytes');
      }
    }

    return MealModel.fromAIJson(
      mealJson,
      mealType: mealType,
      imageBytes: imageBytes,
    );
  }

  /// Generate meal using direct API (AIService)
  Future<MealModel> _generateMealViaDirectAPI(String ingredients, MealType? mealType) async {
    debugPrint('[MealService] Using direct API...');

    // Reset fallback to try real API first
    _aiService.resetFallback();

    // Create system context message
    final systemMessage = MessageModel.user(_mealGenerationPrompt);

    // Create message for AI
    final userMessage = MessageModel.user(
      'Create a healthy ${mealType?.displayName ?? "meal"} recipe using these ingredients: $ingredients',
    );

    // Step 1: Generate recipe text (JSON)
    debugPrint('[MealService] Generating recipe...');
    final response = await _aiService.sendMessage([systemMessage, userMessage]);

    // Check if response is a fallback/mock response (not JSON)
    if (_isFallbackResponse(response)) {
      debugPrint('[MealService] AI returned fallback response, using generated meal');
      return _generateFallbackMeal(ingredients, mealType);
    }

    // Parse JSON response
    final mealJson = _parseJsonResponse(response);

    // Step 2: Try to generate image using AI (try Vertex AI first for better image gen)
    Uint8List? imageBytes;
    String? imagePrompt = mealJson['image_prompt'] as String?;

    if (imagePrompt != null && imagePrompt.isNotEmpty) {
      debugPrint('[MealService] Generating image with prompt: $imagePrompt');

      // Try Vertex AI Cloud Functions first (better image generation)
      try {
        debugPrint('[MealService] Trying Vertex AI for image...');
        imageBytes = await _vertexAIService.generateMealImage(imagePrompt);
      } catch (e) {
        debugPrint('[MealService] Vertex AI image failed: $e');
      }

      // Fallback to direct API if Vertex AI fails
      if (imageBytes == null) {
        debugPrint('[MealService] Trying direct API for image...');
        imageBytes = await _aiService.generateImage(imagePrompt);
      }

      if (imageBytes != null) {
        debugPrint('[MealService] Image generated successfully: ${imageBytes.length} bytes');
      } else {
        debugPrint('[MealService] Image generation returned null, using placeholder');
      }
    }

    // Convert to MealModel with image bytes if available
    return MealModel.fromAIJson(
      mealJson,
      mealType: mealType,
      imageBytes: imageBytes,
    );
  }

  /// Check if response is a fallback/mock response
  bool _isFallbackResponse(String response) {
    // Mock responses don't contain JSON structure
    return !response.contains('{') ||
           response.contains('network is unstable') ||
           response.contains('Mạng hơi có vấn đề');
  }

  /// Generate a fallback meal when AI is unavailable
  MealModel _generateFallbackMeal(String ingredients, MealType? mealType) {
    final ingredientList = ingredients
        .split(RegExp(r'[,\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final mainIngredient = ingredientList.isNotEmpty
        ? ingredientList.first
        : 'mixed ingredients';

    final mealName = '${mainIngredient.substring(0, 1).toUpperCase()}${mainIngredient.substring(1)} ${mealType?.displayName ?? "Dish"}';

    // Reliable food image URLs from Unsplash
    final foodImages = [
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=800&h=600&fit=crop',
      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&h=600&fit=crop',
    ];
    final imageUrl = foodImages[mainIngredient.hashCode.abs() % foodImages.length];

    return MealModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: mealName,
      description: 'A delicious homemade dish made with ${ingredientList.join(", ")}. Perfect for a healthy meal!',
      type: mealType ?? MealType.lunch,
      calories: 350 + (ingredientList.length * 50),
      protein: 20 + (ingredientList.length * 5),
      carbs: 30 + (ingredientList.length * 8),
      fats: 15 + (ingredientList.length * 3),
      ingredients: ingredientList.map((i) => '$i - as needed').toList(),
      instructions: [
        'Prepare and wash all ingredients.',
        'Cut $mainIngredient into bite-sized pieces.',
        'Heat oil in a pan over medium heat.',
        'Cook the main ingredients until done.',
        'Season with salt and pepper to taste.',
        'Serve hot and enjoy!',
      ],
      imageUrl: imageUrl,
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  /// Parse JSON from AI response
  Map<String, dynamic> _parseJsonResponse(String response) {
    try {
      // Clean response - remove markdown code blocks if present
      String cleanedResponse = response.trim();

      // Remove markdown code block markers
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      } else if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }

      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
      }

      cleanedResponse = cleanedResponse.trim();

      // Find JSON object boundaries
      final startIndex = cleanedResponse.indexOf('{');
      final endIndex = cleanedResponse.lastIndexOf('}');

      if (startIndex == -1 || endIndex == -1 || startIndex >= endIndex) {
        throw MealServiceException('Invalid JSON response from AI');
      }

      final jsonString = cleanedResponse.substring(startIndex, endIndex + 1);

      // Parse JSON
      final parsed = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate required fields
      if (!parsed.containsKey('name') || !parsed.containsKey('calories')) {
        throw MealServiceException('AI response missing required fields');
      }

      return parsed;
    } catch (e) {
      if (e is MealServiceException) rethrow;
      throw MealServiceException('Failed to parse AI response: $e');
    }
  }

  /// Get meals for a specific date (placeholder - can be extended with Firestore)
  Future<List<MealModel>> getMealsForDate(DateTime date) async {
    // TODO: Implement Firestore fetching
    return [];
  }

  /// Save meal to storage (placeholder - can be extended with Firestore)
  Future<void> saveMeal(MealModel meal) async {
    // TODO: Implement Firestore saving
    debugPrint('[MealService] Saving meal: ${meal.name}');
  }

  /// Dispose resources
  void dispose() {
    _aiService.dispose();
    _vertexAIService.dispose();
  }
}

