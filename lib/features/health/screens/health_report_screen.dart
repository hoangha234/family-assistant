import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../cubit/health_report_cubit.dart';

class HealthReportScreen extends StatelessWidget {
  const HealthReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HealthReportCubit(),
      child: const HealthReportView(),
    );
  }
}

class HealthReportView extends StatelessWidget {
  const HealthReportView({super.key});

  final Color primaryColor = const Color(0xFF13EC80);
  final Color bgLight = const Color(0xFFF8F9FA);
  final Color bgDark = const Color(0xFF102219);
  final Color textDark = const Color(0xFF111814);
  final Color textMuted = const Color(0xFF6B7280);

  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF13EC80); // Good - Green
    if (score >= 50) return const Color(0xFFFFD54F); // Avg - Light Yellow
    return const Color(0xFFEF5350); // Bad - Red
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? bgDark : bgLight;
    final cardColor = isDarkMode ? const Color(0xFF1A2E24) : Colors.white;
    final textColor = isDarkMode ? Colors.white : textDark;

    return BlocBuilder<HealthReportCubit, HealthReportState>(
      builder: (context, state) {
        if (state.isLoading) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          backgroundColor: backgroundColor,
          body: RefreshIndicator(
            onRefresh: () => context.read<HealthReportCubit>().refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(context, textColor),
                const SizedBox(height: 8),
                _buildWeeklyActivitySection(context, state, cardColor, textColor, isDarkMode),
                const SizedBox(height: 24),
                _buildAveragesSection(state, cardColor, textColor, isDarkMode),
                const SizedBox(height: 24),
                _buildNutritionBreakdownSection(state, cardColor, textColor, isDarkMode),
                const SizedBox(height: 24),
                _buildWeeklyCaloriesCard(state),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, Color textColor) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back, color: textColor, size: 24),
          ),
          const Spacer(),
          Text(
            "Health Report",
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 24), 
        ],
      ),
    );
  }

  Widget _buildWeeklyActivitySection(BuildContext context, HealthReportState state, Color cardColor, Color textColor, bool isDarkMode) {
    final scores = state.weeklyScores;
    final currentColor = _getScoreColor(state.currentScore);

    String dateRange = "This Week";
    if (state.weeklyData.isNotEmpty) {
      final firstDay = DateTime.tryParse(state.weeklyData.first.date);
      final lastDay = DateTime.tryParse(state.weeklyData.last.date);
      if (firstDay != null && lastDay != null) {
        final formatter = DateFormat('MMM d');
        dateRange = "${formatter.format(firstDay)} - ${formatter.format(lastDay)}";
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Weekly Health Summary",
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateRange,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 16),
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
                // Activity Score row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Weekly Health Score",
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.currentScore.round().toString(),
                          style: GoogleFonts.manrope(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: currentColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: state.isScoreChangePositive ? const Color(0xFF13EC80).withAlpha(26) : Colors.red.withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(state.isScoreChangePositive ? Icons.trending_up : Icons.trending_down, 
                               color: state.isScoreChangePositive ? const Color(0xFF13EC80) : Colors.red, 
                               size: 14),
                          const SizedBox(width: 4),
                          Text(
                            state.scoreChangeText,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: state.isScoreChangePositive ? const Color(0xFF13EC80) : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Bar chart
                SizedBox(
                  height: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (index) {
                      if (index >= scores.length) return const SizedBox();
                      final score = scores[index];
                      final isSelected = state.selectedDayIndex == index;
                      final dayDate = DateTime.tryParse(state.weeklyData[index].date);
                      final dayLbl = dayDate != null ? DateFormat('EEE').format(dayDate) : "";
                      return GestureDetector(
                        onTap: () => context.read<HealthReportCubit>().selectDay(index),
                        child: _buildActivityBar(score / 100, isSelected, _getScoreColor(score), dayLbl),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBar(double heightFactor, bool isHighlighted, Color barColor, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 36,
          height: 70 * heightFactor.clamp(0.05, 1.0),
          decoration: BoxDecoration(
            color: barColor.withAlpha(isHighlighted ? 255 : 120),
            borderRadius: BorderRadius.circular(8),
            border: isHighlighted ? Border.all(color: Colors.white, width: 1.5) : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
            color: isHighlighted ? textDark : textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildAveragesSection(HealthReportState state, Color cardColor, Color textColor, bool isDarkMode) {
    final stepsFmt = state.averageSteps >= 1000 
        ? "${(state.averageSteps / 1000).toStringAsFixed(1)}k" 
        : state.averageSteps.round().toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Averages",
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
               Expanded(
                child: _buildAverageCard(
                  cardColor: cardColor,
                  textColor: textColor,
                  color: const Color(0xFF13EC80),
                  icon: Icons.bedtime_outlined,
                  value: "${state.averageSleepHours.toStringAsFixed(1)}h",
                  label: "Sleep",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAverageCard(
                  cardColor: cardColor,
                  textColor: textColor,
                  color: Colors.blue,
                  icon: Icons.directions_run,
                  value: stepsFmt,
                  label: "Steps",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAverageCard(
                  cardColor: cardColor,
                  textColor: textColor,
                  color: Colors.cyan,
                  icon: Icons.water_drop_outlined,
                  value: "${state.averageWaterLiters.toStringAsFixed(1)}L",
                  label: "Water",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAverageCard({
    required Color cardColor,
    required Color textColor,
    required Color color,
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionBreakdownSection(HealthReportState state, Color cardColor, Color textColor, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Nutrition Breakdown",
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
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
            child: Row(
              children: [
                // Donut chart
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CustomPaint(
                    painter: DonutChartPainter(
                      carbsPercent: state.carbsPercent,
                      proteinPercent: state.proteinPercent,
                      fatsPercent: state.fatsPercent,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Total",
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              color: textMuted,
                            ),
                          ),
                          Text(
                            "100%",
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                // Legend
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(const Color(0xFF13EC80), "Carbs", "${(state.carbsPercent * 100).toStringAsFixed(0)}%", textColor),
                      const SizedBox(height: 12),
                      _buildLegendItem(Colors.blue, "Protein", "${(state.proteinPercent * 100).toStringAsFixed(0)}%", textColor),
                      const SizedBox(height: 12),
                      _buildLegendItem(Colors.red, "Fats", "${(state.fatsPercent * 100).toStringAsFixed(0)}%", textColor),
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

  Widget _buildLegendItem(Color color, String label, String value, Color textColor) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: textColor,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyCaloriesCard(HealthReportState state) {
    final formatter = NumberFormat('#,###');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF13EC80),
              const Color(0xFF13EC80).withAlpha(200),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF13EC80).withAlpha(77),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Weekly Calories Burned",
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formatter.format(state.totalCaloriesBurned),
                      style: GoogleFonts.manrope(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "kcal",
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withAlpha(200),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final double carbsPercent;
  final double proteinPercent;
  final double fatsPercent;

  DonutChartPainter({
    required this.carbsPercent,
    required this.proteinPercent,
    required this.fatsPercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (carbsPercent == 0 && proteinPercent == 0 && fatsPercent == 0) return;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 12.0;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -90 * 3.14159 / 180;

    // Carbs (green)
    paint.color = const Color(0xFF13EC80);
    if(carbsPercent > 0) {
      canvas.drawArc(
        rect,
        startAngle,
        carbsPercent * 2 * 3.14159,
        false,
        paint,
      );
    }

    // Protein (blue)
    paint.color = Colors.blue;
    if(proteinPercent > 0) {
      canvas.drawArc(
        rect,
        startAngle + carbsPercent * 2 * 3.14159,
        proteinPercent * 2 * 3.14159,
        false,
        paint,
      );
    }

    // Fats (red)
    paint.color = Colors.red;
    if(fatsPercent > 0) {
      canvas.drawArc(
        rect,
        startAngle + (carbsPercent + proteinPercent) * 2 * 3.14159,
        fatsPercent * 2 * 3.14159,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
