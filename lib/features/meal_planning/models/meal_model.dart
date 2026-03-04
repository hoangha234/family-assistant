import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Type of meal (breakfast, lunch, dinner, snack)
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  static MealType fromString(String value) {
    return MealType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MealType.lunch,
    );
  }
}

/// Model representing a meal
class MealModel {
  final String id;
  final String name;
  final String description;
  final MealType type;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final List<String> ingredients;
  final List<String> instructions;
  final String imageUrl;
  final String? imagePrompt;
  final Uint8List? imageBytes; // AI-generated image bytes
  final DateTime date;
  final DateTime createdAt;

  const MealModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.ingredients,
    required this.instructions,
    required this.imageUrl,
    this.imagePrompt,
    this.imageBytes,
    required this.date,
    required this.createdAt,
  });

  /// Check if meal has AI-generated image
  bool get hasGeneratedImage => imageBytes != null && imageBytes!.isNotEmpty;

  /// Create from JSON (AI response)
  factory MealModel.fromAIJson(
    Map<String, dynamic> json, {
    MealType? mealType,
    Uint8List? imageBytes,
  }) {
    final name = json['name'] as String? ?? 'Untitled Meal';

    // Generate placeholder image URL based on meal name (used if no AI image)
    final searchTerm = _extractFoodKeyword(name);
    final placeholderImage = _generateFoodImageUrl(searchTerm);

    return MealModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: json['description'] as String? ?? '',
      type: mealType ?? MealType.lunch,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toInt() ?? 0,
      carbs: (json['carbs'] as num?)?.toInt() ?? 0,
      fats: (json['fats'] as num?)?.toInt() ?? 0,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      instructions: (json['instructions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      imageUrl: placeholderImage,
      imagePrompt: json['image_prompt'] as String?,
      imageBytes: imageBytes,
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  /// Extract main food keyword from meal name
  static String _extractFoodKeyword(String name) {
    // Common food keywords to search for
    final foodKeywords = [
      'chicken', 'beef', 'pork', 'fish', 'salmon', 'shrimp', 'tofu',
      'rice', 'pasta', 'noodle', 'bread', 'salad', 'soup', 'stew',
      'egg', 'vegetable', 'fruit', 'steak', 'burger', 'sandwich',
      'pizza', 'curry', 'stir-fry', 'grilled', 'roasted', 'fried',
    ];

    final lowerName = name.toLowerCase();
    for (final keyword in foodKeywords) {
      if (lowerName.contains(keyword)) {
        return keyword;
      }
    }

    // Return first word if no keyword found
    return name.split(' ').first.toLowerCase();
  }

  /// Generate food image URL using reliable image services
  static String _generateFoodImageUrl(String keyword) {
    // Use a hash of the keyword to get consistent but varied images
    final hash = keyword.hashCode.abs() % 1000;

    // Reliable Unsplash food photo URLs
    final urls = [
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&h=600&fit=crop', // Default food image
      'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=800&h=600&fit=crop', // Pancakes
      'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&h=600&fit=crop', // Pizza
      'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=800&h=600&fit=crop', // Salad
      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&h=600&fit=crop', // Healthy food
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&h=600&fit=crop', // Gourmet
      'https://images.unsplash.com/photo-1476224203421-9ac39bcb3327?w=800&h=600&fit=crop', // Breakfast
      'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=800&h=600&fit=crop', // Pasta
      'https://images.unsplash.com/photo-1432139555190-58524dae6a55?w=800&h=600&fit=crop', // Steak
      'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=800&h=600&fit=crop', // Salmon
    ];

    // Select image based on keyword hash for variety
    return urls[hash % urls.length];
  }

  /// Create from Firestore document
  factory MealModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MealModel.fromMap(data, doc.id);
  }

  /// Create from Map
  factory MealModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return MealModel(
      id: docId ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      type: MealType.fromString(map['type'] as String? ?? 'lunch'),
      calories: (map['calories'] as num?)?.toInt() ?? 0,
      protein: (map['protein'] as num?)?.toInt() ?? 0,
      carbs: (map['carbs'] as num?)?.toInt() ?? 0,
      fats: (map['fats'] as num?)?.toInt() ?? 0,
      ingredients: (map['ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      instructions: (map['instructions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      imageUrl: map['imageUrl'] as String? ?? '',
      imagePrompt: map['imagePrompt'] as String?,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'ingredients': ingredients,
      'instructions': instructions,
      'imageUrl': imageUrl,
      'imagePrompt': imagePrompt,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Convert to JSON (for nested storage in meal_plans collection)
  /// Note: imageBytes is NOT stored here - it should be uploaded to Firebase Storage
  /// and the resulting URL should be set as imageUrl before calling toJson()
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'ingredients': ingredients,
      'instructions': instructions,
      'imageUrl': imageUrl,
      'imagePrompt': imagePrompt,
      // DO NOT store imageBase64 - it causes SQLiteBlobTooBigException
      // Images should be uploaded to Firebase Storage instead
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON (for nested retrieval from meal_plans collection)
  factory MealModel.fromJson(Map<String, dynamic> json) {
    // Try to decode compressed base64 image if available
    Uint8List? decodedImageBytes;
    final compressedBase64 = json['imageBase64Compressed'] as String?;
    if (compressedBase64 != null && compressedBase64.isNotEmpty) {
      try {
        decodedImageBytes = base64Decode(compressedBase64);
      } catch (e) {
        // Failed to decode, leave as null
      }
    }

    return MealModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: MealType.fromString(json['type'] as String? ?? 'lunch'),
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toInt() ?? 0,
      carbs: (json['carbs'] as num?)?.toInt() ?? 0,
      fats: (json['fats'] as num?)?.toInt() ?? 0,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      instructions: (json['instructions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      imageUrl: json['imageUrl'] as String? ?? '',
      imagePrompt: json['imagePrompt'] as String?,
      // Load from compressed base64 if available
      imageBytes: decodedImageBytes,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Copy with updated values
  MealModel copyWith({
    String? id,
    String? name,
    String? description,
    MealType? type,
    int? calories,
    int? protein,
    int? carbs,
    int? fats,
    List<String>? ingredients,
    List<String>? instructions,
    String? imageUrl,
    String? imagePrompt,
    Uint8List? imageBytes,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return MealModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePrompt: imagePrompt ?? this.imagePrompt,
      imageBytes: imageBytes ?? this.imageBytes,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'MealModel(id: $id, name: $name, type: $type, calories: $calories)';
  }
}

