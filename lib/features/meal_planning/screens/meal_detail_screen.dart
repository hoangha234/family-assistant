import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../cubit/meal_detail_cubit.dart';
import '../models/meal_model.dart';

class MealDetailScreen extends StatelessWidget {
  final MealModel? meal;

  const MealDetailScreen({super.key, this.meal});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = MealDetailCubit();
        // Initialize ingredients from meal data
        final ingredients = meal?.ingredients ?? [
          "Fresh Salmon Fillets - 2 large fillets (approx 400g)",
          "Organic Lemons - 2 sliced into rounds",
          "Extra Virgin Olive Oil - 2 tablespoons",
          "Asparagus Spears - 1 bunch, trimmed",
          "Garlic Powder & Sea Salt - To taste",
        ];
        cubit.initIngredients(ingredients);
        return cubit;
      },
      child: MealDetailView(meal: meal),
    );
  }
}

class MealDetailView extends StatelessWidget {
  final MealModel? meal;

  const MealDetailView({super.key, this.meal});

  final Color primaryColor = const Color(0xFF13EC80);
  final Color bgLight = const Color(0xFFF6F8F7);
  final Color bgDark = const Color(0xFF102219);
  final Color textDark = const Color(0xFF111814);
  final Color textGreenMuted = const Color(0xFF618975);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? bgDark : bgLight;
    final cardColor = isDarkMode ? const Color(0xFF1A2E24) : Colors.white;
    final textColor = isDarkMode ? Colors.white : textDark;
    final mutedColor = isDarkMode ? const Color(0xFFA0C5B3) : textGreenMuted;

    // Use passed meal data or fallback to defaults
    final mealName = meal?.name ?? "Grilled Lemon Salmon";
    final mealDescription = meal?.description ?? "Rich in Omega-3 fatty acids, this light and zesty meal is perfect for maintaining a balanced diet for the whole family.";
    final mealImage = meal?.imageUrl ?? 'https://images.unsplash.com/photo-1467003909585-2f8a7270028d?q=80&w=800&auto=format&fit=crop';
    final mealCalories = meal?.calories ?? 450;
    final mealProtein = meal?.protein ?? 35;
    final mealCarbs = meal?.carbs ?? 12;
    final mealFats = meal?.fats ?? 22;
    final mealInstructions = meal?.instructions ?? [
      "Preheat oven to 200°C (400°F).",
      "Season salmon with salt, pepper, and garlic powder.",
      "Place salmon on baking sheet with lemon slices.",
      "Drizzle with olive oil.",
      "Bake for 20-25 minutes until cooked through.",
    ];
    final mealType = meal?.type.displayName.toUpperCase() ?? "LUNCH";

    return BlocBuilder<MealDetailCubit, MealDetailState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 360,
                child: _buildHeroImage(
                  imageUrl: mealImage,
                  imageBytes: meal?.imageBytes,
                  primaryColor: primaryColor,
                ),
              ),
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    children: [
                      const SizedBox(height: 280),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(13),
                              blurRadius: 20,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withAlpha(51),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    mealType,
                                    style: GoogleFonts.manrope(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? primaryColor : const Color(0xFF0C8A4A),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.schedule, size: 16, color: mutedColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      "25 mins",
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: mutedColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              mealName,
                              style: GoogleFonts.manrope(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              mealDescription,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                color: mutedColor,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildNutritionCircle("$mealCalories", "CALORIES", (mealCalories / 600).clamp(0.0, 1.0), primaryColor, mutedColor, textColor),
                                _buildNutritionCircle("${mealProtein}g", "PROTEIN", (mealProtein / 50).clamp(0.0, 1.0), primaryColor, mutedColor, textColor, rotation: 12),
                                _buildNutritionCircle("${mealCarbs}g", "CARBS", (mealCarbs / 80).clamp(0.0, 1.0), primaryColor, mutedColor, textColor, rotation: -90),
                                _buildNutritionCircle("${mealFats}g", "FATS", (mealFats / 40).clamp(0.0, 1.0), primaryColor, mutedColor, textColor, rotation: 45),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                _buildTabButton(context, "Ingredients", state.isIngredientsTab, textColor, mutedColor),
                                _buildTabButton(context, "Instructions", !state.isIngredientsTab, textColor, mutedColor),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (state.isIngredientsTab) ...[
                              // Render ingredients from state
                              ...state.ingredients.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                return _buildIngredientItem(
                                  context,
                                  index,
                                  item.name,
                                  item.quantity,
                                  item.isChecked,
                                  primaryColor,
                                  textColor,
                                  mutedColor,
                                  isDarkMode,
                                );
                              }),
                            ] else ...[
                              ...mealInstructions.asMap().entries.map((entry) {
                                final index = entry.key;
                                final instruction = entry.value;
                                return _buildInstructionItem(
                                  index + 1,
                                  instruction,
                                  primaryColor,
                                  textColor,
                                  mutedColor,
                                  isDarkMode,
                                );
                              }),
                            ],
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildGlassButton(Icons.arrow_back, context),
                        Row(
                          children: [
                            _buildGlassButton(Icons.favorite_border, context),
                            const SizedBox(width: 8),
                            _buildGlassButton(Icons.share, context),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 34),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        backgroundColor,
                        backgroundColor.withAlpha(242),
                        backgroundColor.withAlpha(0),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: const Color(0xFF102219),
                      elevation: 8,
                      shadowColor: primaryColor.withAlpha(77),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.analytics_outlined),
                        const SizedBox(width: 8),
                        Text(
                          "View Health Impact",
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build hero image - uses AI-generated bytes if available
  Widget _buildHeroImage({
    required String imageUrl,
    Uint8List? imageBytes,
    required Color primaryColor,
  }) {
    // If we have AI-generated image bytes, use them
    if (imageBytes != null && imageBytes.isNotEmpty) {
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: primaryColor.withAlpha(51),
            child: Center(
              child: Icon(Icons.restaurant, size: 80, color: primaryColor),
            ),
          );
        },
      );
    }

    // Otherwise fall back to network image
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: primaryColor.withAlpha(51),
          child: Center(
            child: Icon(Icons.restaurant, size: 80, color: primaryColor),
          ),
        );
      },
    );
  }

  Widget _buildGlassButton(IconData icon, BuildContext context) {
    return GestureDetector(
      onTap: icon == Icons.arrow_back ? () => Navigator.pop(context) : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(204),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 22),
      ),
    );
  }

  Widget _buildNutritionCircle(
      String value, String label, double percentage, Color primary, Color muted, Color text,
      {double rotation = 0}) {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 4,
                color: primary.withAlpha(51),
              ),
              Transform.rotate(
                angle: rotation * (math.pi / 180),
                child: CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 4,
                  color: primary,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Center(
                child: Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: text,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: muted,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(BuildContext context, String text, bool isSelected, Color textColor, Color mutedColor) {
    final Color currentColor = isSelected ? textColor : mutedColor;
    final Color borderColor = isSelected ? const Color(0xFF13EC80) : Colors.transparent;

    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<MealDetailCubit>().setTab(text == "Ingredients"),
        child: Container(
          padding: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor, width: 2)),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: currentColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientItem(
    BuildContext context,
    int index,
    String name,
    String qty,
    bool isChecked,
    Color primary,
    Color textColor,
    Color muted,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => context.read<MealDetailCubit>().toggleIngredient(index),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isChecked ? primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isChecked ? primary : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                  width: 2,
                ),
              ),
              child: isChecked
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF2D4239) : const Color(0xFFF0F3F2),
                    ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (qty.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      qty,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(int step, String instruction, Color primary, Color textColor, Color muted, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: primary.withAlpha(51),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$step',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF2D4239) : const Color(0xFFF0F3F2),
                  ),
                ),
              ),
              child: Text(
                instruction,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
