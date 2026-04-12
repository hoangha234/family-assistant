import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
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

/// Model for meal plan document in Firestore
class MealPlanDocument {
  final String date;
  final int totalCalories;
  final Map<String, MealModel?> meals;
  final DateTime createdAt;

  MealPlanDocument({
    required this.date,
    required this.totalCalories,
    required this.meals,
    required this.createdAt,
  });

  factory MealPlanDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final mealsData = data['meals'] as Map<String, dynamic>? ?? {};

    final meals = <String, MealModel?>{};
    for (final type in ['breakfast', 'lunch', 'dinner']) {
      if (mealsData[type] != null) {
        meals[type] = MealModel.fromJson(mealsData[type] as Map<String, dynamic>);
      }
    }

    return MealPlanDocument(
      date: data['date'] as String? ?? doc.id,
      totalCalories: (data['totalCalories'] as num?)?.toInt() ?? 0,
      meals: meals,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final mealsMap = <String, dynamic>{};
    meals.forEach((key, value) {
      if (value != null) {
        mealsMap[key] = value.toJson();
      }
    });

    return {
      'date': date,
      'totalCalories': totalCalories,
      'meals': mealsMap,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
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
You are a professional nutrition expert and chef integrated into the "iMate" app.
Your task is to design a meal recipe based strictly on the ingredients provided by the user.

STRICT RULES:
1. Use primarily the ingredients provided by the user.
2. You may add minimal common pantry items (salt, oil, pepper, water, basic spices).

CRITICAL CONTEXT & DAILY BUDGET:
The total daily target for ALL 3 MEALS combined must be EXACTLY 2000 kcal (with an allowed margin of error of +/- 150 kcal, meaning the total should strictly fall between 1850 and 2150 kcal), exactly 120g of protein, about 250g of carbohydrates, and about 60g of fats.
You must logically allocate these limits across Breakfast, Lunch, and Dinner (for example, ~500-600 kcal for Breakfast, ~700-800 kcal for Lunch, ~600-700 kcal for Dinner, adapting as needed to hit the target).
However, you MUST ONLY generate the recipe and details for the SINGLE specific MEAL TYPE requested below.
Ensure the calories and macros for this specific meal are strictly calculated so that it perfectly fits the allocation, ensuring the 3-meal total will meet the 2000 kcal (+/- 150 kcal), 120g protein, 250g carbs, and 60g fat goals.

MEAL TYPE TO GENERATE: {{MEAL_TYPE}}

OUTPUT FORMAT:
You MUST return ONLY valid JSON in this exact structure, with no extra text or markdown blocks:
{
  "name": "Dish name",
  "description": "Short description",
  "calories": 400,
  "protein": 30,
  "carbs": 20,
  "fats": 10,
  "ingredients": ["1. ...", "2. ..."],
  "instructions": ["1. ...", "2. ..."],
  "image_prompt": "Beautiful food photography of..."
}

IMPORTANT:
- Return ONLY the JSON object, nothing else.
- Do NOT wrap in markdown code blocks.
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
      debugPrint('[MealService] Error generating meal: $e');
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
    final systemPrompt = _mealGenerationPrompt.replaceAll('{{MEAL_TYPE}}', mealType?.displayName ?? "meal");
    final prompt = '$systemPrompt\n\nUser Request: Create a healthy ${mealType?.displayName ?? "meal"} recipe using these ingredients: $ingredients';
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
    final systemPrompt = _mealGenerationPrompt.replaceAll('{{MEAL_TYPE}}', mealType?.displayName ?? "meal");
    final systemMessage = MessageModel.user(systemPrompt);

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

      // Validate required fields for either single meal or daily menu
      final isSingleMeal = parsed.containsKey('name');
      final isDailyMenu = parsed.containsKey('daily_summary') && parsed.containsKey('meals');
      
      if (!isSingleMeal && !isDailyMenu) {
        throw MealServiceException('AI response missing required fields');
      }

      return parsed;
    } catch (e) {
      if (e is MealServiceException) rethrow;
      throw MealServiceException('Failed to parse AI response: $e');
    }
  }

  // ===================== FIRESTORE OPERATIONS =====================

  /// Get current user ID
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  /// Get Firestore collection reference for meal plans
  CollectionReference<Map<String, dynamic>> get _mealPlansCollection {
    final uid = _userId;
    if (uid == null) {
      throw MealServiceException('User not authenticated');
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('meal_plans');
  }

  /// Format date to string (yyyy-MM-dd)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get meals for a specific date from Firestore
  Future<List<MealModel>> getMealsForDate(DateTime date) async {
    try {
      final dateString = _formatDate(date);
      debugPrint('[MealService] Fetching meals for date: $dateString');

      final doc = await _mealPlansCollection.doc(dateString).get();

      if (!doc.exists) {
        debugPrint('[MealService] No meal plan found for $dateString');
        return [];
      }

      // Check for corrupted data (imageBase64 too large)
      final data = doc.data();
      if (data != null && _hasCorruptedImageData(data)) {
        debugPrint('[MealService] Found corrupted imageBase64 data, cleaning up...');
        await _cleanupCorruptedData(dateString, data);
        // Re-fetch after cleanup
        final cleanDoc = await _mealPlansCollection.doc(dateString).get();
        if (!cleanDoc.exists) return [];
        final cleanPlan = MealPlanDocument.fromFirestore(cleanDoc);
        return _extractMeals(cleanPlan);
      }

      final mealPlan = MealPlanDocument.fromFirestore(doc);
      return _extractMeals(mealPlan);
    } catch (e) {
      debugPrint('[MealService] Error fetching meals: $e');
      // If error is due to blob too big, try to clean up
      if (e.toString().contains('Blob') || e.toString().contains('CursorWindow')) {
        debugPrint('[MealService] Detected blob size error, attempting cleanup...');
        try {
          await _cleanupAllCorruptedData();
        } catch (_) {}
      }
      if (e is MealServiceException) rethrow;
      throw MealServiceException('Failed to fetch meals: $e');
    }
  }

  /// Extract meals from MealPlanDocument
  List<MealModel> _extractMeals(MealPlanDocument mealPlan) {
    final meals = <MealModel>[];
    mealPlan.meals.forEach((type, meal) {
      if (meal != null) {
        meals.add(meal);
      }
    });
    meals.sort((a, b) => a.type.index.compareTo(b.type.index));
    debugPrint('[MealService] Found ${meals.length} meals');
    return meals;
  }

  /// Check if data contains corrupted imageBase64 (too large)
  bool _hasCorruptedImageData(Map<String, dynamic> data) {
    final meals = data['meals'] as Map<String, dynamic>?;
    if (meals == null) return false;

    for (final mealData in meals.values) {
      if (mealData is Map<String, dynamic>) {
        // Only flag OLD uncompressed imageBase64 (not the new compressed one)
        // Old corrupted data uses 'imageBase64', new compressed uses 'imageBase64Compressed'
        final imageBase64 = mealData['imageBase64'] as String?;
        if (imageBase64 != null && imageBase64.length > 500000) {
          return true; // Has very large uncompressed base64 image data
        }
      }
    }
    return false;
  }

  /// Clean up corrupted imageBase64 data from a document (only old uncompressed)
  Future<void> _cleanupCorruptedData(String dateString, Map<String, dynamic> data) async {
    try {
      final meals = Map<String, dynamic>.from(data['meals'] ?? {});
      bool needsUpdate = false;

      for (final key in meals.keys) {
        final mealData = meals[key];
        // Only remove old uncompressed 'imageBase64', keep 'imageBase64Compressed'
        if (mealData is Map<String, dynamic> && mealData.containsKey('imageBase64')) {
          final cleanMeal = Map<String, dynamic>.from(mealData);
          cleanMeal.remove('imageBase64');
          meals[key] = cleanMeal;
          needsUpdate = true;
        }
      }

      if (needsUpdate) {
        await _mealPlansCollection.doc(dateString).update({'meals': meals});
        debugPrint('[MealService] Cleaned up imageBase64 from $dateString');
      }
    } catch (e) {
      debugPrint('[MealService] Error cleaning up: $e');
    }
  }

  /// Clean up all corrupted data in meal_plans collection
  Future<void> _cleanupAllCorruptedData() async {
    try {
      debugPrint('[MealService] Cleaning up all corrupted meal data...');
      final snapshot = await _mealPlansCollection.limit(50).get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (_hasCorruptedImageData(data)) {
          await _cleanupCorruptedData(doc.id, data);
        }
      }
      debugPrint('[MealService] Cleanup complete');
    } catch (e) {
      debugPrint('[MealService] Error during cleanup: $e');
    }
  }

  /// Save meal to Firestore for a specific date
  /// If meal has imageBytes, uploads to Firebase Storage first
  Future<void> saveMealToDate(MealModel meal, DateTime date) async {
    try {
      final dateString = _formatDate(date);
      debugPrint('[MealService] Saving meal "${meal.name}" to date: $dateString');

      // If meal has AI-generated image bytes, try to upload to Firebase Storage
      MealModel mealToSave = meal;
      String? compressedBase64;

      if (meal.imageBytes != null && meal.imageBytes!.isNotEmpty) {
        debugPrint('[MealService] Processing AI image (${meal.imageBytes!.length} bytes)...');

        // First, try Firebase Storage
        debugPrint('[MealService] Attempting Firebase Storage upload...');
        final imageUrl = await _uploadImageToStorage(
          meal.imageBytes!,
          dateString,
          meal.type.name,
          meal.id,
        );

        if (imageUrl != null) {
          debugPrint('[MealService] Storage upload successful: $imageUrl');
          mealToSave = meal.copyWith(imageUrl: imageUrl);
        } else {
          // Storage failed - compress and save as base64
          debugPrint('[MealService] Storage failed, compressing image for base64...');
          compressedBase64 = await _compressImageToBase64(meal.imageBytes!);
          if (compressedBase64 != null) {
            debugPrint('[MealService] Compressed to ${compressedBase64.length} chars');
          }
        }
      }

      final docRef = _mealPlansCollection.doc(dateString);
      final existingDoc = await docRef.get();

      Map<String, dynamic> mealsMap = {};
      int totalCalories = 0;

      if (existingDoc.exists) {
        final data = existingDoc.data()!;
        mealsMap = Map<String, dynamic>.from(data['meals'] ?? {});
      }

      // Convert meal to JSON
      final mealJson = mealToSave.toJson();

      // Add compressed base64 if Storage failed
      if (compressedBase64 != null) {
        mealJson['imageBase64Compressed'] = compressedBase64;
      }

      mealsMap[mealToSave.type.name] = mealJson;

      // Calculate total calories
      for (final type in ['breakfast', 'lunch', 'dinner']) {
        if (mealsMap[type] != null) {
          final mealData = mealsMap[type] as Map<String, dynamic>;
          totalCalories += (mealData['calories'] as num?)?.toInt() ?? 0;
        }
      }

      // Save to Firestore
      await docRef.set({
        'date': dateString,
        'totalCalories': totalCalories,
        'meals': mealsMap,
        'createdAt': existingDoc.exists
            ? existingDoc.data()!['createdAt']
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('[MealService] Meal saved successfully');
    } catch (e) {
      debugPrint('[MealService] Error saving meal: $e');
      if (e is MealServiceException) rethrow;
      throw MealServiceException('Failed to save meal: $e');
    }
  }

  /// Compress image to small base64 string (< 500KB)
  Future<String?> _compressImageToBase64(Uint8List imageBytes) async {
    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // Resize to max 400px width/height to reduce size significantly
      final resized = img.copyResize(
        image,
        width: image.width > image.height ? 400 : null,
        height: image.height >= image.width ? 400 : null,
        interpolation: img.Interpolation.linear,
      );

      // Encode as JPEG with quality 60 (good balance of size vs quality)
      final compressed = img.encodeJpg(resized, quality: 60);

      debugPrint('[MealService] Image compressed: ${imageBytes.length} -> ${compressed.length} bytes');

      // Convert to base64
      final base64 = base64Encode(compressed);

      // Check if still too large (> 500KB base64 = ~375KB binary)
      if (base64.length > 500000) {
        debugPrint('[MealService] Still too large, compressing more...');
        // Try even smaller
        final smallerResized = img.copyResize(resized, width: 300);
        final smallerCompressed = img.encodeJpg(smallerResized, quality: 50);
        return base64Encode(smallerCompressed);
      }

      return base64;
    } catch (e) {
      debugPrint('[MealService] Error compressing image: $e');
      return null;
    }
  }

  /// Upload image bytes to Firebase Storage and return download URL
  Future<String?> _uploadImageToStorage(
    Uint8List imageBytes,
    String dateString,
    String mealType,
    String mealId,
  ) async {
    try {
      final uid = _userId;
      if (uid == null) return null;

      // Create unique path: users/{uid}/meal_images/{date}/{mealType}_{mealId}.jpg
      final fileName = '${mealType}_$mealId.jpg';
      final storagePath = 'users/$uid/meal_images/$dateString/$fileName';

      debugPrint('[MealService] Uploading to: $storagePath');

      final ref = FirebaseStorage.instance.ref().child(storagePath);

      // Upload with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'mealType': mealType,
          'date': dateString,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = await ref.putData(imageBytes, metadata);

      if (uploadTask.state == TaskState.success) {
        final downloadUrl = await ref.getDownloadURL();
        debugPrint('[MealService] Upload successful: $downloadUrl');
        return downloadUrl;
      }

      return null;
    } catch (e) {
      debugPrint('[MealService] Error uploading image: $e');
      // Don't fail the whole save operation if image upload fails
      // Just use the placeholder URL
      return null;
    }
  }

  /// Save meal to storage (legacy method - uses current date)
  Future<void> saveMeal(MealModel meal) async {
    await saveMealToDate(meal, DateTime.now());
  }

  /// Delete a meal from a specific date
  Future<void> deleteMealFromDate(MealType mealType, DateTime date) async {
    try {
      final dateString = _formatDate(date);
      debugPrint('[MealService] Deleting ${mealType.name} from date: $dateString');

      final docRef = _mealPlansCollection.doc(dateString);
      final existingDoc = await docRef.get();

      if (!existingDoc.exists) {
        return;
      }

      final data = existingDoc.data()!;
      final mealsMap = Map<String, dynamic>.from(data['meals'] ?? {});

      // Remove the specific meal type
      mealsMap.remove(mealType.name);

      // Recalculate total calories
      int totalCalories = 0;
      for (final type in ['breakfast', 'lunch', 'dinner']) {
        if (mealsMap[type] != null) {
          final mealData = mealsMap[type] as Map<String, dynamic>;
          totalCalories += (mealData['calories'] as num?)?.toInt() ?? 0;
        }
      }

      // Update or delete document
      if (mealsMap.isEmpty) {
        await docRef.delete();
      } else {
        await docRef.update({
          'totalCalories': totalCalories,
          'meals': mealsMap,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('[MealService] Meal deleted successfully');
    } catch (e) {
      debugPrint('[MealService] Error deleting meal: $e');
      if (e is MealServiceException) rethrow;
      throw MealServiceException('Failed to delete meal: $e');
    }
  }

  /// Get meal history (last N days with data)
  Future<List<MealPlanDocument>> getMealHistory({int limit = 10}) async {
    try {
      debugPrint('[MealService] Fetching meal history (limit: $limit)');

      final querySnapshot = await _mealPlansCollection
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      final history = <MealPlanDocument>[];

      for (final doc in querySnapshot.docs) {
        try {
          // Check for corrupted data first
          final data = doc.data();
          if (_hasCorruptedImageData(data)) {
            debugPrint('[MealService] Found corrupted data in ${doc.id}, cleaning...');
            await _cleanupCorruptedData(doc.id, data);
          }
          history.add(MealPlanDocument.fromFirestore(doc));
        } catch (e) {
          debugPrint('[MealService] Error parsing doc ${doc.id}: $e');
          // Skip corrupted documents
        }
      }

      debugPrint('[MealService] Found ${history.length} days with meal data');
      return history;
    } catch (e) {
      debugPrint('[MealService] Error fetching meal history: $e');
      // If error is due to blob too big, try cleanup
      if (e.toString().contains('Blob') || e.toString().contains('CursorWindow')) {
        debugPrint('[MealService] Blob error detected, attempting cleanup...');
        try {
          await _cleanupAllCorruptedData();
          // Return empty list after cleanup - user can retry
          return [];
        } catch (_) {}
      }
      if (e is MealServiceException) rethrow;
      throw MealServiceException('Failed to fetch meal history: $e');
    }
  }

  /// Check if a date has meal data
  Future<bool> hasDataForDate(DateTime date) async {
    try {
      final dateString = _formatDate(date);
      final doc = await _mealPlansCollection.doc(dateString).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get dates with meal data for a specific month
  Future<Set<int>> getDatesWithDataForMonth(DateTime month) async {
    try {
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0);

      final startString = _formatDate(startDate);
      final endString = _formatDate(endDate);

      final querySnapshot = await _mealPlansCollection
          .where('date', isGreaterThanOrEqualTo: startString)
          .where('date', isLessThanOrEqualTo: endString)
          .get();

      final datesWithData = <int>{};
      for (final doc in querySnapshot.docs) {
        final dateString = doc.id;
        final day = int.tryParse(dateString.split('-').last);
        if (day != null) {
          datesWithData.add(day);
        }
      }

      return datesWithData;
    } catch (e) {
      debugPrint('[MealService] Error fetching dates with data: $e');
      return {};
    }
  }

  /// Dispose resources
  void dispose() {
    _aiService.dispose();
    _vertexAIService.dispose();
  }
}

