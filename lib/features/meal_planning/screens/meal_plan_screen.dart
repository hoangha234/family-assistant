import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../cubit/meal_plan_cubit.dart';
import '../models/meal_model.dart';
import 'meal_detail_screen.dart';
import 'meal_history_screen.dart';

class MealPlanScreen extends StatelessWidget {
  const MealPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MealPlanView();
  }
}

class MealPlanView extends StatelessWidget {
  const MealPlanView({super.key});

  final Color primaryColor = const Color(0xFF13EC80);
  final Color bgLight = const Color(0xFFF8F9FA);
  final Color bgDark = const Color(0xFF102219);
  final Color textDark = const Color(0xFF111814);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? bgDark : bgLight;
    final textColor = isDarkMode ? Colors.white : textDark;
    final cardColor = isDarkMode ? Colors.grey[800]! : Colors.white;

    return BlocConsumer<MealPlanCubit, MealPlanState>(
      listener: (context, state) {
        // Show error snackbar if needed
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
          context.read<MealPlanCubit>().clearError();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: Stack(
            children: [
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _buildTopBar(context, textColor),
                    _buildDateStrip(context, state, isDarkMode),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 100),
                        child: Column(
                          children: [
                            _buildNutritionSummary(state, cardColor, textColor, isDarkMode, primaryColor),
                            _buildSectionHeader(context, "Today's Meals", textColor, primaryColor),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: [
                                  // Breakfast
                                  _buildMealSlot(
                                    context: context,
                                    meal: state.getMealByType(MealType.breakfast),
                                    mealType: MealType.breakfast,
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    isDarkMode: isDarkMode,
                                  ),
                                  const SizedBox(height: 16),
                                  // Lunch
                                  _buildMealSlot(
                                    context: context,
                                    meal: state.getMealByType(MealType.lunch),
                                    mealType: MealType.lunch,
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    isDarkMode: isDarkMode,
                                  ),
                                  const SizedBox(height: 16),
                                  // Dinner
                                  _buildMealSlot(
                                    context: context,
                                    meal: state.getMealByType(MealType.dinner),
                                    mealType: MealType.dinner,
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    isDarkMode: isDarkMode,
                                  ),
                                  const SizedBox(height: 24),
                                  _buildAskAIButton(context, primaryColor),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build meal slot - either meal card or empty card
  Widget _buildMealSlot({
    required BuildContext context,
    required MealModel? meal,
    required MealType mealType,
    required Color cardColor,
    required Color textColor,
    required bool isDarkMode,
  }) {
    if (meal != null) {
      return Dismissible(
        key: Key('meal_${meal.id}_${meal.type.name}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4)],
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
        ),
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Delete Meal", style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                content: Text("Are you sure you want to delete ${meal.name}? This will also remove the calories from today's Health progress.", style: GoogleFonts.manrope()),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text("Cancel", style: GoogleFonts.manrope(color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text("Delete", style: GoogleFonts.manrope(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          );
        },
        onDismissed: (direction) {
          context.read<MealPlanCubit>().deleteMeal(meal.type);
        },
        child: _buildMealCard(
          title: meal.name,
          type: meal.type.displayName,
          kcal: meal.calories.toString(),
          carbs: "${meal.carbs}g",
          protein: "${meal.protein}g",
          fat: "${meal.fats}g",
          imageUrl: meal.imageUrl,
          imageBytes: meal.imageBytes,
          cardColor: cardColor,
          textColor: textColor,
          primaryColor: primaryColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MealDetailScreen(meal: meal),
              ),
            );
          },
        ),
      );
    } else {
      return _buildEmptyMealCard(
        mealType.displayName,
        cardColor,
        isDarkMode,
        primaryColor,
        onTap: () => _showAIBottomSheet(context, mealType),
      );
    }
  }

  Widget _buildTopBar(BuildContext context, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
          ),
          Text(
            "Daily Meal Planner",
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          GestureDetector(
            onTap: () => _showMonthPicker(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.calendar_today, color: textColor, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  /// Show month picker dialog
  void _showMonthPicker(BuildContext context) {
    final cubit = context.read<MealPlanCubit>();
    final currentMonth = cubit.state.currentMonth;
    final currentYear = DateTime.now().year;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomContext) {
        return BlocProvider.value(
          value: cubit,
          child: _MonthPickerSheet(
            currentMonth: currentMonth,
            currentYear: currentYear,
            primaryColor: primaryColor,
          ),
        );
      },
    );
  }

  /// Build date strip with full calendar
  Widget _buildDateStrip(BuildContext context, MealPlanState state, bool isDarkMode) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    final monthName = months[state.currentMonth.month - 1];
    final year = state.currentMonth.year;

    return Column(
      children: [
        // Month header with navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => context.read<MealPlanCubit>().previousMonth(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.chevron_left,
                    color: isDarkMode ? Colors.white70 : Colors.grey[700],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.read<MealPlanCubit>().goToToday(),
                child: Column(
                  children: [
                    Text(
                      '$monthName $year',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : textDark,
                      ),
                    ),
                    if (!state.isToday(state.selectedDate))
                      Text(
                        'Tap to go to today',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          color: primaryColor,
                        ),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.read<MealPlanCubit>().nextMonth(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    color: isDarkMode ? Colors.white70 : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Days list - horizontal scroll
        SizedBox(
          height: 80,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: state.daysInCurrentMonth,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final day = index + 1;
              final date = DateTime(state.currentMonth.year, state.currentMonth.month, day);
              final isSelected = state.isSelected(date);
              final isToday = state.isToday(date);

              // Get weekday name
              final weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
              final weekday = weekdays[date.weekday - 1];

              return GestureDetector(
                onTap: () => context.read<MealPlanCubit>().selectDate(date),
                child: Container(
                  width: 48,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor
                        : (isDarkMode ? Colors.grey[800] : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: isToday && !isSelected
                        ? Border.all(color: primaryColor, width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        weekday,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? textDark
                              : (isDarkMode ? Colors.white70 : Colors.black54),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$day',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? textDark
                              : (isDarkMode ? Colors.white : textDark),
                        ),
                      ),
                      if (isToday && !isSelected)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _buildNutritionSummary(MealPlanState state, Color cardColor, Color textColor, bool isDarkMode, Color primaryColor) {
    final totalCalories = state.totalCalories;
    final progress = state.calorieProgress;
    final progressPercent = (progress * 100).toInt();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total Daily Calories",
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "$totalCalories ",
                        style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      ),
                      TextSpan(
                        text: "/ 2,000 kcal",
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(51),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$progressPercent% of goal",
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? primaryColor : const Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[100],
                    color: primaryColor,
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Text(
                      "$progressPercent%",
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color textColor, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          GestureDetector(
            onTap: () async {
              final selectedDate = await Navigator.push<DateTime>(
                context,
                MaterialPageRoute(
                  builder: (context) => const MealHistoryScreen(),
                ),
              );
              if (selectedDate != null && context.mounted) {
                context.read<MealPlanCubit>().selectDate(selectedDate);
              }
            },
            child: Text(
              "View History",
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard({
    required String title,
    required String type,
    required String kcal,
    required String carbs,
    required String protein,
    required String fat,
    required String imageUrl,
    Uint8List? imageBytes,
    required Color cardColor,
    required Color textColor,
    required Color primaryColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: _buildMealImage(
                imageUrl: imageUrl,
                imageBytes: imageBytes,
                type: type,
                primaryColor: primaryColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type.toUpperCase(),
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              title,
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: kcal,
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            TextSpan(
                              text: " kcal",
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMacroItem("Carbs", carbs, primaryColor),
                      const SizedBox(width: 16),
                      _buildMacroItem("Protein", protein, primaryColor),
                      const SizedBox(width: 16),
                      _buildMacroItem("Fat", fat, primaryColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build meal image - uses AI-generated bytes if available, otherwise network image
  Widget _buildMealImage({
    required String imageUrl,
    Uint8List? imageBytes,
    required String type,
    required Color primaryColor,
  }) {
    // If we have AI-generated image bytes, use them
    if (imageBytes != null && imageBytes.isNotEmpty) {
      return Image.memory(
        imageBytes,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder(type, primaryColor);
        },
      );
    }

    // Otherwise fall back to network image
    return Image.network(
      imageUrl,
      height: 160,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildImagePlaceholder(type, primaryColor);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 160,
          width: double.infinity,
          color: Colors.grey.withAlpha(30),
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: primaryColor,
            ),
          ),
        );
      },
    );
  }

  /// Build placeholder when image fails to load
  Widget _buildImagePlaceholder(String type, Color primaryColor) {
    return Container(
      height: 160,
      width: double.infinity,
      color: primaryColor.withAlpha(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant, size: 48, color: primaryColor),
          const SizedBox(height: 8),
          Text(
            type,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, Color primaryColor) {
    return Row(
      children: [
        Icon(Icons.circle, size: 12, color: primaryColor),
        const SizedBox(width: 4),
        Text(
          "$value $label",
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyMealCard(String mealName, Color cardColor, bool isDarkMode, Color primaryColor, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: DashedRectPainter(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          strokeWidth: 2,
          gap: 5,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealName.toUpperCase(),
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    "Plan your ${mealName.toLowerCase()}",
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, color: primaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAskAIButton(BuildContext context, Color primaryColor) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withAlpha(102),
                blurRadius: 15,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => _showAIBottomSheet(context, null),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF111814)),
                const SizedBox(width: 8),
                Text(
                  "Ask AI for Suggestions",
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111814),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Get personalized recipes based on your nutrition goals",
          style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  /// Show AI meal generation bottom sheet
  void _showAIBottomSheet(BuildContext context, MealType? preselectedType) {
    final cubit = context.read<MealPlanCubit>();
    if (preselectedType != null) {
      cubit.setMealType(preselectedType);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return BlocProvider.value(
          value: cubit,
          child: _AIBottomSheetContent(
            primaryColor: primaryColor,
            preselectedType: preselectedType,
          ),
        );
      },
    );
  }
}

/// AI Bottom Sheet Content Widget
class _AIBottomSheetContent extends StatefulWidget {
  final Color primaryColor;
  final MealType? preselectedType;

  const _AIBottomSheetContent({
    required this.primaryColor,
    this.preselectedType,
  });

  @override
  State<_AIBottomSheetContent> createState() => _AIBottomSheetContentState();
}

class _AIBottomSheetContentState extends State<_AIBottomSheetContent> {
  final TextEditingController _ingredientsController = TextEditingController();
  MealType _selectedMealType = MealType.lunch;

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.preselectedType ?? MealType.lunch;
  }

  @override
  void dispose() {
    _ingredientsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF1A2E24) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF111814);
    final mutedColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return BlocConsumer<MealPlanCubit, MealPlanState>(
      listener: (context, state) {
        // Close bottom sheet after adding meal
        if (state.generatedPreview == null && state.meals.isNotEmpty && !state.isGenerating) {
          // Meal was added, can close
        }
      },
      builder: (context, state) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: widget.primaryColor, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        "AI Meal Suggestion",
                        style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tell me what ingredients you have, and I'll create a delicious recipe for you!",
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Meal Type Selector
                  Text(
                    "Meal Type",
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: MealType.values.where((t) => t != MealType.snack).map((type) {
                      final isSelected = _selectedMealType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedMealType = type);
                            context.read<MealPlanCubit>().setMealType(type);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? widget.primaryColor
                                  : (isDarkMode ? Colors.grey[800] : Colors.grey[100]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              type.displayName,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? const Color(0xFF111814)
                                    : mutedColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Ingredients Input
                  Text(
                    "Your Ingredients",
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ingredientsController,
                    maxLines: 3,
                    style: GoogleFonts.manrope(color: textColor),
                    decoration: InputDecoration(
                      hintText: "e.g., chicken, broccoli, garlic, olive oil...",
                      hintStyle: GoogleFonts.manrope(color: mutedColor),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: widget.primaryColor, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Generate Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: state.isGenerating
                          ? null
                          : () {
                              context.read<MealPlanCubit>().getMealSuggestion(
                                _ingredientsController.text,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        disabledBackgroundColor: widget.primaryColor.withAlpha(128),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: state.isGenerating
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: const Color(0xFF111814),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Generating...",
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF111814),
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              "Generate Recipe",
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF111814),
                              ),
                            ),
                    ),
                  ),

                  // Preview Card
                  if (state.generatedPreview != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: widget.primaryColor, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (state.generatedPreview?.imageBytes != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                state.generatedPreview!.imageBytes!,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          else if (state.isGenerating)
                             Container(
                                height: 160,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(color: widget.primaryColor),
                                ),
                              ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: widget.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                "Recipe Generated!",
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: widget.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            state.generatedPreview!.name,
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.generatedPreview!.description,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: mutedColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildMiniMacro("🔥", "${state.generatedPreview!.calories} kcal", textColor),
                              const SizedBox(width: 16),
                              _buildMiniMacro("💪", "${state.generatedPreview!.protein}g protein", textColor),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: state.isGenerating
                                    ? null
                                    : () {
                                      context.read<MealPlanCubit>().getMealSuggestion(
                                        _ingredientsController.text,
                                      );
                                    },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: widget.primaryColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: Text(
                                    "Regenerate",
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.bold,
                                      color: widget.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    context.read<MealPlanCubit>().addGeneratedMealToToday();
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: widget.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: Text(
                                    "Add to Today",
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF111814),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Error Message
                  if (state.errorMessage != null && state.generatedPreview == null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniMacro(String emoji, String text, Color textColor) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final double strokeWidth;
  final Color color;
  final double gap;

  DashedRectPainter(
      {this.strokeWidth = 5.0, this.color = Colors.red, this.gap = 5.0});

  @override
  void paint(Canvas canvas, Size size) {
    Paint dashedPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    double x = size.width;
    double y = size.height;

    Path topPath = getDashedPath(
      a: const math.Point(0, 0),
      b: math.Point(x, 0),
      gap: gap,
    );

    Path rightPath = getDashedPath(
      a: math.Point(x, 0),
      b: math.Point(x, y),
      gap: gap,
    );

    Path bottomPath = getDashedPath(
      a: math.Point(0, y),
      b: math.Point(x, y),
      gap: gap,
    );

    Path leftPath = getDashedPath(
      a: const math.Point(0, 0),
      b: math.Point(0, y),
      gap: gap,
    );

    canvas.drawPath(topPath, dashedPaint);
    canvas.drawPath(rightPath, dashedPaint);
    canvas.drawPath(bottomPath, dashedPaint);
    canvas.drawPath(leftPath, dashedPaint);
  }

  Path getDashedPath({
    required math.Point<double> a,
    required math.Point<double> b,
    required double gap,
  }) {
    Size size = Size(b.x - a.x, b.y - a.y);
    Path path = Path();
    path.moveTo(a.x, a.y);
    bool shouldDraw = true;
    math.Point currentPoint = math.Point(a.x, a.y);

    num radians = math.atan(size.height / (size.width == 0 ? 0.000001 : size.width));

    double dx = math.cos(radians) * gap < 0
        ? math.cos(radians) * gap * -1
        : math.cos(radians) * gap;

    double dy = math.sin(radians) * gap < 0
        ? math.sin(radians) * gap * -1
        : math.sin(radians) * gap;

    while (currentPoint.x <= b.x && currentPoint.y <= b.y) {
      shouldDraw
          ? path.lineTo(currentPoint.x.toDouble(), currentPoint.y.toDouble())
          : path.moveTo(currentPoint.x.toDouble(), currentPoint.y.toDouble());
      shouldDraw = !shouldDraw;
      currentPoint = math.Point(
        currentPoint.x + dx,
        currentPoint.y + dy,
      );
    }
    return path;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

/// Month Picker Bottom Sheet
class _MonthPickerSheet extends StatelessWidget {
  final DateTime currentMonth;
  final int currentYear;
  final Color primaryColor;

  const _MonthPickerSheet({
    required this.currentMonth,
    required this.currentYear,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF1A2E24) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF111814);

    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Title
          Text(
            'Select Month',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$currentYear',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          // Month grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final isSelected = (index + 1) == currentMonth.month &&
                                  currentMonth.year == currentYear;
              final isCurrentMonth = (index + 1) == DateTime.now().month &&
                                      currentYear == DateTime.now().year;

              return GestureDetector(
                onTap: () {
                  final selectedMonth = DateTime(currentYear, index + 1);
                  context.read<MealPlanCubit>().changeMonth(selectedMonth);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor
                        : (isDarkMode ? Colors.grey[800] : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(12),
                    border: isCurrentMonth && !isSelected
                        ? Border.all(color: primaryColor, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      months[index].substring(0, 3),
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? const Color(0xFF111814)
                            : (isDarkMode ? Colors.white70 : Colors.grey[700]),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // Go to today button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                context.read<MealPlanCubit>().goToToday();
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Go to Today',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

