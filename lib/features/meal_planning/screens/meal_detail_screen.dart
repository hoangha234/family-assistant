import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../cubit/meal_detail_cubit.dart';

class MealDetailScreen extends StatelessWidget {
  const MealDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MealDetailCubit(),
      child: const MealDetailView(),
    );
  }
}

class MealDetailView extends StatelessWidget {
  const MealDetailView({super.key});

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
                child: Image.network(
                  'https://images.unsplash.com/photo-1467003909585-2f8a7270028d?q=80&w=800&auto=format&fit=crop',
                  fit: BoxFit.cover,
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
                              color: Colors.black.withOpacity(0.05),
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
                                    color: primaryColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "HEART HEALTHY",
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
                              "Grilled Lemon Salmon",
                              style: GoogleFonts.manrope(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Rich in Omega-3 fatty acids, this light and zesty meal is perfect for maintaining a balanced diet for the whole family.",
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
                                _buildNutritionCircle("450", "CALORIES", 0.75, primaryColor, mutedColor, textColor),
                                _buildNutritionCircle("35g", "PROTEIN", 0.60, primaryColor, mutedColor, textColor, rotation: 12),
                                _buildNutritionCircle("12g", "CARBS", 0.25, primaryColor, mutedColor, textColor, rotation: -90),
                                _buildNutritionCircle("22g", "FATS", 0.40, primaryColor, mutedColor, textColor, rotation: 45),
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
                              _buildIngredientItem("Fresh Salmon Fillets", "2 large fillets (approx 400g)", true, primaryColor, textColor, mutedColor, isDarkMode),
                              _buildIngredientItem("Organic Lemons", "2 sliced into rounds", false, primaryColor, textColor, mutedColor, isDarkMode),
                              _buildIngredientItem("Extra Virgin Olive Oil", "2 tablespoons", false, primaryColor, textColor, mutedColor, isDarkMode),
                              _buildIngredientItem("Asparagus Spears", "1 bunch, trimmed", false, primaryColor, textColor, mutedColor, isDarkMode),
                              _buildIngredientItem("Garlic Powder & Sea Salt", "To taste", false, primaryColor, textColor, mutedColor, isDarkMode),
                            ] else ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Text("Instructions content goes here...", style: TextStyle(color: textColor)),
                              ),
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
                        backgroundColor.withOpacity(0.95),
                        backgroundColor.withOpacity(0.0),
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
                      shadowColor: primaryColor.withOpacity(0.3),
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

  Widget _buildGlassButton(IconData icon, BuildContext context) {
    return GestureDetector(
      onTap: icon == Icons.arrow_back ? () => Navigator.pop(context) : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                color: primary.withOpacity(0.2),
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

  Widget _buildIngredientItem(String name, String qty, bool isChecked, Color primary, Color textColor, Color muted, bool isDark) {
    return Padding(
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
                  const SizedBox(height: 2),
                  Text(
                    qty,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
