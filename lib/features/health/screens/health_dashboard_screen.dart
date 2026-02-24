import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../cubit/health_dashboard_cubit.dart';

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
  final Color heartRed = const Color(0xFFFF4D6D);
  final Color textDark = const Color(0xFF111814);
  final Color textGreenMuted = const Color(0xFF618975);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? bgDark : bgLight;
    final cardColor = isDarkMode ? const Color(0xFF1A2E24) : Colors.white;
    final textColor = isDarkMode ? Colors.white : textDark;
    final borderColor = isDarkMode ? Colors.white.withOpacity(0.05) : const Color(0xFFE2E8F0);

    return BlocBuilder<HealthDashboardCubit, HealthDashboardState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  children: [
                    _buildHeader(context, textColor, isDarkMode),
                    _buildHeartRateCard(cardColor, textColor, borderColor, isDarkMode),
                    _buildQuickStatsGrid(cardColor, textColor, borderColor, isDarkMode),
                    _buildWeeklySummary(cardColor, textColor, borderColor, isDarkMode),
                    _buildVitalsTrend(cardColor, textColor, borderColor, isDarkMode),
                  ],
                ),
              ),

            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Color textColor, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      color: isDarkMode ? bgDark.withOpacity(0.8) : bgLight.withOpacity(0.8),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCircleBtn(Icons.arrow_back_ios_new, isDarkMode),
              Text(
                "Health Dashboard",
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              _buildCircleBtn(Icons.calendar_today, isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, bool isDarkMode) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Icon(icon, size: 20, color: isDarkMode ? Colors.white : textDark),
    );
  }

  Widget _buildHeartRateCard(Color cardColor, Color textColor, Color borderColor, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Heart Rate",
                        style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? primaryColor.withOpacity(0.7) : textGreenMuted)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text("72",
                            style: GoogleFonts.manrope(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: textColor)),
                        const SizedBox(width: 4),
                        Text("BPM",
                            style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? primaryColor.withOpacity(0.7) : textGreenMuted)),
                      ],
                    )
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF450a0a) : const Color(0xFFFFF0F3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.favorite, size: 14, color: heartRed),
                      const SizedBox(width: 4),
                      Text("LIVE",
                          style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: heartRed,
                              letterSpacing: 1.0)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              width: double.infinity,
              child: CustomPaint(
                painter: HeartRatePainter(color: heartRed),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ["12pm", "1pm", "2pm", "3pm", "4pm"]
                  .map((e) => Text(e,
                      style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white.withOpacity(0.4) : textGreenMuted)))
                  .toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsGrid(Color cardColor, Color textColor, Color borderColor, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              cardColor,
              borderColor,
              customIcon: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60, height: 60,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 3,
                      color: isDarkMode ? Colors.white.withOpacity(0.05) : const Color(0xFFF0F4F2),
                    ),
                  ),
                  SizedBox(
                    width: 60, height: 60,
                    child: CircularProgressIndicator(
                      value: 0.75,
                      strokeWidth: 3,
                      color: primaryColor,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Icon(Icons.directions_walk, color: primaryColor, size: 24),
                ],
              ),
              value: "8,432",
              label: "STEPS",
              textColor: textColor,
              labelColor: isDarkMode ? Colors.white.withOpacity(0.5) : textGreenMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              cardColor,
              borderColor,
              customIcon: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white.withOpacity(0.05) : const Color(0xFFF0F4F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bedtime, color: Colors.indigo, size: 28),
              ),
              value: "7h 45m",
              label: "SLEEP",
              textColor: textColor,
              labelColor: isDarkMode ? Colors.white.withOpacity(0.5) : textGreenMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              cardColor,
              borderColor,
              customIcon: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white.withOpacity(0.05) : const Color(0xFFF0F4F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.water_drop, color: Colors.blue, size: 28),
              ),
              value: "1.2L",
              label: "HYDRATION",
              textColor: textColor,
              labelColor: isDarkMode ? Colors.white.withOpacity(0.5) : textGreenMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(Color bg, Color border, {
    required Widget customIcon,
    required String value,
    required String label,
    required Color textColor,
    required Color labelColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          customIcon,
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          Text(label, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: labelColor)),
        ],
      ),
    );
  }

  Widget _buildWeeklySummary(Color cardColor, Color textColor, Color borderColor, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Weekly Health Summary", style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Great progress!", style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 4),
                      Text(
                        "You're 15% more active than last week! Great job keeping the family moving.",
                        style: GoogleFonts.manrope(fontSize: 12, color: isDarkMode ? Colors.white.withOpacity(0.6) : textGreenMuted),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("View Full Report", style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: bgDark)),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward, size: 14, color: bgDark),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 120,
                  height: 100,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? bgDark.withOpacity(0.5) : bgLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar(0.4),
                      _buildBar(0.6),
                      _buildBar(0.5),
                      _buildBar(0.8),
                      _buildBar(1.0),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBar(double heightFactor) {
    return FractionallySizedBox(
      heightFactor: heightFactor,
      child: Container(
        width: 12,
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.2 + (0.8 * heightFactor)),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ),
    );
  }

  Widget _buildVitalsTrend(Color cardColor, Color textColor, Color borderColor, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Vitals Trend", style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              Text("Monthly View", style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                _buildTrendItem(
                  icon: Icons.monitor_weight_outlined,
                  iconColor: Colors.orange,
                  iconBg: isDarkMode ? Colors.orange.withOpacity(0.2) : Colors.orange.shade100,
                  title: "Weight Trend",
                  subtitle: "-1.2kg since October",
                  textColor: textColor,
                  mutedColor: isDarkMode ? Colors.white.withOpacity(0.5) : textGreenMuted,
                ),
                Divider(height: 1, color: borderColor),
                _buildTrendItem(
                  icon: Icons.favorite_border,
                  iconColor: Colors.purple,
                  iconBg: isDarkMode ? Colors.purple.withOpacity(0.2) : Colors.purple.shade100,
                  title: "Blood Pressure",
                  subtitle: "118/75 mmHg (Optimal)",
                  textColor: textColor,
                  mutedColor: isDarkMode ? Colors.white.withOpacity(0.5) : textGreenMuted,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTrendItem({
    required IconData icon, required Color iconColor, required Color iconBg,
    required String title, required String subtitle, required Color textColor, required Color mutedColor
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
              Text(subtitle, style: GoogleFonts.manrope(fontSize: 12, color: mutedColor)),
            ],
          ),
          const Spacer(),
          Icon(Icons.chevron_right, color: mutedColor),
        ],
      ),
    );
  }





}

class HeartRatePainter extends CustomPainter {
  final Color color;
  HeartRatePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;
    
    path.moveTo(0, h * 0.8);
    path.cubicTo(w*0.05, h*0.7, w*0.1, h*0.9, w*0.15, h*0.6);
    path.cubicTo(w*0.2, h*0.3, w*0.25, h*0.5, w*0.3, h*0.4);
    path.cubicTo(w*0.35, h*0.3, w*0.4, h*0.7, w*0.45, h*0.6);
    path.cubicTo(w*0.5, h*0.5, w*0.55, h*0.2, w*0.6, h*0.4);
    path.cubicTo(w*0.65, h*0.6, w*0.7, h*0.4, w*0.75, h*0.5);
    path.cubicTo(w*0.8, h*0.6, w*0.85, h*0.3, w*0.9, h*0.5);
    path.cubicTo(w*0.95, h*0.7, w, h*0.6, w, h);

    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
