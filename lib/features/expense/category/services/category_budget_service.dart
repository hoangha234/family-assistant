import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_budget_model.dart';

/// Custom exception for Category Budget service errors
class CategoryBudgetServiceException implements Exception {
  final String message;
  CategoryBudgetServiceException(this.message);

  @override
  String toString() => 'CategoryBudgetServiceException: $message';
}

/// Service to manage category budgets in Firestore
class CategoryBudgetService {
  final FirebaseFirestore _firestore;
  static const String _collection = 'category_budgets';
  static const String _expensesCollection = 'expenses';

  CategoryBudgetService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get collection reference
  CollectionReference<Map<String, dynamic>> get _budgetsRef =>
      _firestore.collection(_collection);

  /// Stream all category budgets
  Stream<List<CategoryBudget>> streamCategoryBudgets() {
    return _budgetsRef.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CategoryBudget.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Fetch all category budgets (one-time)
  Future<List<CategoryBudget>> fetchAllCategoryBudgets() async {
    try {
      final snapshot = await _budgetsRef.orderBy('name').get();
      return snapshot.docs
          .map((doc) => CategoryBudget.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw CategoryBudgetServiceException('Failed to fetch category budgets: $e');
    }
  }

  /// Get a single category budget by ID
  Future<CategoryBudget?> getCategoryBudget(String categoryId) async {
    try {
      final doc = await _budgetsRef.doc(categoryId).get();
      if (!doc.exists) return null;
      return CategoryBudget.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw CategoryBudgetServiceException('Failed to get category budget: $e');
    }
  }

  /// Get category budget by name
  Future<CategoryBudget?> getCategoryBudgetByName(String name) async {
    try {
      final snapshot = await _budgetsRef
          .where('name', isEqualTo: name)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return CategoryBudget.fromMap(doc.data(), doc.id);
    } catch (e) {
      throw CategoryBudgetServiceException('Failed to get category by name: $e');
    }
  }

  /// Create a new category budget
  Future<String> createCategoryBudget(CategoryBudget budget) async {
    try {
      final docRef = await _budgetsRef.add(budget.toMap());
      return docRef.id;
    } catch (e) {
      throw CategoryBudgetServiceException('Failed to create category budget: $e');
    }
  }

  /// Update category budget amount
  Future<void> updateCategoryBudget(String categoryId, double newBudget) async {
    try {
      print('[CategoryBudgetService] Updating doc $categoryId with monthlyBudget=$newBudget');
      await _budgetsRef.doc(categoryId).update({
        'monthlyBudget': newBudget,
        'updatedAt': Timestamp.now(),
      });
      print('[CategoryBudgetService] Update completed successfully');
    } catch (e) {
      print('[CategoryBudgetService] Update failed: $e');
      throw CategoryBudgetServiceException('Failed to update category budget: $e');
    }
  }

  /// Update total spent for a category
  Future<void> updateTotalSpent(String categoryId, double totalSpent) async {
    try {
      await _budgetsRef.doc(categoryId).update({
        'totalSpent': totalSpent,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw CategoryBudgetServiceException('Failed to update total spent: $e');
    }
  }

  /// Delete a category budget
  Future<void> deleteCategoryBudget(String categoryId) async {
    try {
      await _budgetsRef.doc(categoryId).delete();
    } catch (e) {
      throw CategoryBudgetServiceException('Failed to delete category budget: $e');
    }
  }

  /// Calculate total spent per category from expenses collection
  /// This is the aggregation query for current month
  Future<Map<String, double>> calculateSpentPerCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Default to current month
      final now = DateTime.now();
      final start = startDate ?? DateTime(now.year, now.month, 1);
      final end = endDate ?? DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      print('[CategoryBudgetService] Calculating spent from $start to $end');

      // Fetch all expenses and filter in code to avoid needing composite index
      final snapshot = await _firestore
          .collection(_expensesCollection)
          .get();

      print('[CategoryBudgetService] Total expenses documents: ${snapshot.docs.length}');

      final Map<String, double> categoryTotals = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String? ?? '';
        final category = data['category'] as String? ?? 'Other';
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        // Filter: only expenses, within date range
        if (type == 'expense' && createdAt != null) {
          if (createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
              createdAt.isBefore(end.add(const Duration(seconds: 1)))) {
            categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
            print('[CategoryBudgetService] Found expense: $category = $amount');
          }
        }
      }

      print('[CategoryBudgetService] Category totals: $categoryTotals');
      return categoryTotals;
    } catch (e) {
      print('[CategoryBudgetService] Error calculating spent: $e');
      throw CategoryBudgetServiceException('Failed to calculate spent per category: $e');
    }
  }

  /// Sync category budgets with calculated totals
  Future<List<CategoryBudget>> syncCategoryBudgetsWithExpenses() async {
    try {
      print('[CategoryBudgetService] Starting sync...');

      // Get all budgets
      final budgets = await fetchAllCategoryBudgets();
      print('[CategoryBudgetService] Found ${budgets.length} budgets');

      // Calculate current month spending
      final spentPerCategory = await calculateSpentPerCategory();
      print('[CategoryBudgetService] Spent per category: $spentPerCategory');

      // Update each budget with calculated spent
      final updatedBudgets = <CategoryBudget>[];

      for (final budget in budgets) {
        final spent = spentPerCategory[budget.name] ?? 0.0;
        print('[CategoryBudgetService] Updating ${budget.name}: spent=$spent');

        // Update in Firestore
        await updateTotalSpent(budget.id, spent);

        // Add to result list
        updatedBudgets.add(budget.copyWith(totalSpent: spent));
      }

      print('[CategoryBudgetService] Sync completed');
      return updatedBudgets;
    } catch (e) {
      print('[CategoryBudgetService] Sync error: $e');
      throw CategoryBudgetServiceException('Failed to sync category budgets: $e');
    }
  }

  /// Initialize default categories if none exist
  Future<void> initializeDefaultCategories() async {
    try {
      final existing = await fetchAllCategoryBudgets();
      if (existing.isNotEmpty) return; // Already initialized

      for (final category in DefaultCategories.categories) {
        final budget = CategoryBudget(
          id: '',
          name: category['name'] as String,
          monthlyBudget: category['suggestedBudget'] as double,
          totalSpent: 0.0,
        );
        await createCategoryBudget(budget);
      }
    } catch (e) {
      throw CategoryBudgetServiceException('Failed to initialize default categories: $e');
    }
  }

  /// Get total allocated budget across all categories
  Future<double> getTotalAllocatedBudget() async {
    try {
      final budgets = await fetchAllCategoryBudgets();
      double total = 0.0;
      for (final budget in budgets) {
        total += budget.monthlyBudget;
      }
      return total;
    } catch (e) {
      throw CategoryBudgetServiceException('Failed to get total allocated budget: $e');
    }
  }
}

