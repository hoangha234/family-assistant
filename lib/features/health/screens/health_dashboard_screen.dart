import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cubit/health_dashboard_cubit.dart';
import '../models/food_analysis_model.dart';

class HealthDashboardScreen extends StatelessWidget {
  const HealthDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HealthDashboardCubit(),
      child: const HealthDashboardView(),
    );
  }
}

class HealthDashboardView extends StatelessWidget {
  const HealthDashboardView({super.key});

  final Color primaryColor = const Color(0xFF13EC80);
  final Color bgLight = const Color(0xFFF8F9FA);
  final Color bgDark = const Color(0xFF102219);
  final Color textDark = const Color(0xFF111814);
  final Color textMuted = const Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? bgDark : bgLight;
    final cardColor = isDarkMode ? const Color(0xFF1A2E24) : Colors.white;
    final textColor = isDarkMode ? Colors.white : textDark;

    return BlocConsumer<HealthDashboardCubit, HealthDashboardState>(
      listener: (context, state) {
        // Show snackbar on scan success
        if (state.status == HealthDashboardStatus.scanSuccess && state.lastScannedFood != null) {
          _showScanResultSnackbar(context, state.lastScannedFood!);
        }
        // Show error snackbar
        if (state.status == HealthDashboardStatus.scanError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to analyze food: ${state.errorMessage ?? "Unknown error"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAppBar(context, textColor, isDarkMode),
                    const SizedBox(height: 16),
                    _buildStepsCard(context, state, cardColor, textColor, isDarkMode),
                    const SizedBox(height: 16),
                    _buildSleepWaterRow(state, cardColor, textColor, isDarkMode),
                    const SizedBox(height: 24),
                    _buildTodayHealthSummary(state, cardColor, textColor, isDarkMode),
                    const SizedBox(height: 24),
                    _buildWeeklyOverview(cardColor, textColor, isDarkMode),
                  ],
                ),
              ),
              // Floating Scan Button
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: _buildFloatingScanButton(context, state),
                ),
              ),
              // Loading overlay when scanning
              if (state.status == HealthDashboardStatus.scanning)
                _buildScanningOverlay(),
            ],
          ),
        );
      },
    );
  }

  /// Show snackbar with scan result
  void _showScanResultSnackbar(BuildContext context, FoodAnalysis food) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✅ ${food.foodName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${food.calories} cal • ${food.protein}g protein • ${food.carbs}g carbs • ${food.fat}g fat',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: primaryColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Build scanning overlay
  Widget _buildScanningOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 16),
              Text(
                'Analyzing food...',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Color textColor, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back, color: textColor, size: 24),
          ),
          Text(
            "Health Dashboard",
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Icon(Icons.calendar_today_outlined, color: textColor, size: 22),
        ],
      ),
    );
  }

  Widget _buildStepsCard(BuildContext context, HealthDashboardState state, Color cardColor, Color textColor, bool isDarkMode) {
    final int currentSteps = state.steps;
    final int goalSteps = state.stepGoal;
    final double progress = state.stepProgress;
    final int percentage = state.stepPercentage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left side - Steps info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_walk, color: primaryColor, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "Steps",
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentSteps.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},'),
                    style: GoogleFonts.manrope(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Goal: ${goalSteps.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            // Right side - Circular progress
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 8,
                      backgroundColor: isDarkMode
                          ? Colors.white.withAlpha(26)
                          : Colors.grey.shade200,
                      color: Colors.transparent,
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.transparent,
                      color: primaryColor,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    "$percentage%",
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
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

  Widget _buildSleepWaterRow(HealthDashboardState state, Color cardColor, Color textColor, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Sleep Card
          Expanded(
            child: _buildMetricCard(
              cardColor: cardColor,
              textColor: textColor,
              isDarkMode: isDarkMode,
              icon: Icons.bedtime_outlined,
              iconColor: Colors.indigo,
              label: "Sleep",
              value: state.sleepFormatted,
              goal: "Goal: ${state.sleepGoal.toInt()}h",
              progress: state.sleepProgress,
            ),
          ),
          const SizedBox(width: 12),
          // Water Card
          Expanded(
            child: _buildMetricCard(
              cardColor: cardColor,
              textColor: textColor,
              isDarkMode: isDarkMode,
              icon: Icons.water_drop_outlined,
              iconColor: Colors.lightBlue,
              label: "Water",
              value: state.waterFormatted,
              goal: "Goal: ${state.waterGoal}L",
              progress: state.waterProgress,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required Color cardColor,
    required Color textColor,
    required bool isDarkMode,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String goal,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDarkMode
                  ? Colors.white.withAlpha(26)
                  : Colors.grey.shade200,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            goal,
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayHealthSummary(HealthDashboardState state, Color cardColor, Color textColor, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Health Summary",
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  label: "Calories",
                  current: state.dailyCalories,
                  goal: state.caloriesGoal,
                  unit: "kcal",
                  textColor: textColor,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 16),
                _buildSummaryRow(
                  label: "Protein",
                  current: state.protein,
                  goal: state.proteinGoal,
                  unit: "g",
                  textColor: textColor,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 16),
                _buildSummaryRow(
                  label: "Activity",
                  current: state.activityMinutes,
                  goal: state.activityGoal,
                  unit: "min",
                  textColor: textColor,
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required int current,
    required int goal,
    required String unit,
    required Color textColor,
    required bool isDarkMode,
  }) {
    final double progress = current / goal;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            Text(
              "$current / $goal $unit",
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: isDarkMode
                ? Colors.white.withAlpha(26)
                : Colors.grey.shade200,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyOverview(Color cardColor, Color textColor, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Weekly Overview",
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                "Full Report",
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Day labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                    return SizedBox(
                      width: 36,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textMuted,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // Bar chart
                SizedBox(
                  height: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildWeekBar(0.5, false, isDarkMode),
                      _buildWeekBar(0.65, false, isDarkMode),
                      _buildWeekBar(0.75, true, isDarkMode), // Today (Wednesday)
                      _buildWeekBar(0.4, false, isDarkMode),
                      _buildWeekBar(0.55, false, isDarkMode),
                      _buildWeekBar(0.85, false, isDarkMode),
                      _buildWeekBar(0.7, false, isDarkMode),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekBar(double heightFactor, bool isToday, bool isDarkMode) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 36,
          height: 100 * heightFactor,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: isToday
                  ? [primaryColor, primaryColor.withAlpha(200)]
                  : [
                      primaryColor.withAlpha(77),
                      primaryColor.withAlpha(128),
                    ],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: isToday
                ? [
                    BoxShadow(
                      color: primaryColor.withAlpha(77),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingScanButton(BuildContext context, HealthDashboardState state) {
    final bool isScanning = state.status == HealthDashboardStatus.scanning;

    return GestureDetector(
      onTap: isScanning ? null : () => _showScanOptions(context),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isScanning ? primaryColor.withAlpha(150) : primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withAlpha(100),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          isScanning ? Icons.hourglass_empty : Icons.camera_alt_outlined,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  /// Show options for scanning (camera or gallery)
  void _showScanOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomContext) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final backgroundColor = isDarkMode ? const Color(0xFF1A2E24) : Colors.white;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Scan Food',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Take a photo or select from gallery to analyze nutrition',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildScanOptionButton(
                      context: context,
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(bottomContext);
                        context.read<HealthDashboardCubit>().scanMeal();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildScanOptionButton(
                      context: context,
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(bottomContext);
                        context.read<HealthDashboardCubit>().scanMealFromGallery();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Build scan option button
  Widget _buildScanOptionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: primaryColor.withAlpha(26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withAlpha(51)),
        ),
        child: Column(
          children: [
            Icon(icon, color: primaryColor, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
