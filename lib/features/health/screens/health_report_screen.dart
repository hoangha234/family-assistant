import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
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
  final Color bgLight = const Color(0xFFF6F8F7);
  final Color bgDark = const Color(0xFF102219);
  final Color textDark = const Color(0xFF111814);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? bgDark : bgLight;
    final cardColor = isDarkMode ? const Color(0xFF111827) : Colors.white;
    final textColor = isDarkMode ? Colors.white : textDark;
    final borderColor = isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey[100]!;

    return BlocBuilder<HealthReportCubit, HealthReportState>(
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
                    _buildHeader(context, textColor, isDarkMode),
                    _buildSegmentedControl(context, state, isDarkMode),
                    _buildChartSection(cardColor, textColor, borderColor),
                    _buildAIInsightCard(cardColor, textColor, borderColor, isDarkMode),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        "Weekly Averages",
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    _buildMetricGrid(cardColor, textColor, borderColor, isDarkMode),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomNav(isDarkMode, backgroundColor),
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
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: (isDarkMode ? bgDark : bgLight).withOpacity(0.8),
        border: Border(bottom: BorderSide(color: isDarkMode ? Colors.white10 : Colors.grey[200]!)),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.arrow_back_ios, color: textColor, size: 20),
              Text(
                "Health Report",
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: textColor, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedControl(BuildContext context, HealthReportState state, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: ['Weekly', 'Monthly'].map((timeframe) {
            final isSelected = state.selectedTimeframe == timeframe;
            return Expanded(
              child: GestureDetector(
                onTap: () => context.read<HealthReportCubit>().setTimeframe(timeframe),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? (isDarkMode ? Colors.grey[700] : Colors.white) 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected 
                        ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)] 
                        : [],
                  ),
                  child: Text(
                    timeframe,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected 
                          ? (isDarkMode ? Colors.white : textDark) 
                          : (isDarkMode ? Colors.grey[400] : Colors.grey[500]),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildChartSection(Color cardColor, Color textColor, Color borderColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Steps Taken", style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text("8,452", style: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.bold, color: textColor, height: 1)),
                const SizedBox(width: 8),
                Text("avg/day", style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.trending_up, color: primaryColor, size: 16),
                const SizedBox(width: 4),
                Text("+15% vs last week", style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 140,
              width: double.infinity,
              child: CustomPaint(
                painter: StepsChartPainter(color: primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"].map((day) => 
                Text(day, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[400]))
              ).toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAIInsightCard(Color cardColor, Color textColor, Color borderColor, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 0,
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                        child: const Icon(Icons.smart_toy, size: 12, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text("AI HEALTH INSIGHTS", style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 0.5)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Your activity is soaring!", style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.manrope(fontSize: 14, color: isDarkMode ? Colors.grey[400] : Colors.grey[600], height: 1.5),
                      children: [
                        const TextSpan(text: "Your activity increased by "),
                        TextSpan(text: "15%", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                        const TextSpan(text: " this week! You're only 3 days away from hitting your consistency streak."),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.smart_toy_outlined, size: 40, color: primaryColor),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: cardColor, width: 2),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricGrid(Color cardColor, Color textColor, Color borderColor, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              cardColor, borderColor, textColor, isDarkMode,
              icon: Icons.bedtime, iconColor: Colors.blue, iconBg: Colors.blue.withOpacity(0.1),
              label: "Sleep", value: "7h 20m", subtitle: "+5m vs last week", subtitleColor: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildMetricCard(
              cardColor, borderColor, textColor, isDarkMode,
              icon: Icons.favorite, iconColor: Colors.red, iconBg: Colors.red.withOpacity(0.1),
              label: "Heart Rate", value: "72 BPM", subtitle: "Normal Resting", subtitleColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    Color bg, Color border, Color textColor, bool isDark,
    {required IconData icon, required Color iconColor, required Color iconBg,
    required String label, required String value, required String subtitle, required Color subtitleColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Icon(Icons.more_vert, size: 16, color: Colors.grey[300]),
            ],
          ),
          const SizedBox(height: 12),
          Text(label.toUpperCase(), style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: subtitleColor)),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isDarkMode, Color bgColor) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: (isDarkMode ? const Color(0xFF102219) : Colors.white).withOpacity(0.9),
        border: Border(top: BorderSide(color: isDarkMode ? Colors.white10 : Colors.grey[200]!)),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home, "Home"),
                  const SizedBox(width: 48),
                  _buildNavItem(Icons.grid_view, "More"),
                ],
              ),
              Positioned(
                top: -24,
                child: Column(
                  children: [
                    Container(
                      height: 56, width: 56,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: const Icon(Icons.chat_bubble, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text("Ask AI", style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.grey[400]),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[400])),
      ],
    );
  }
}

class StepsChartPainter extends CustomPainter {
  final Color color;
  StepsChartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(0, h * 0.7);
    path.cubicTo(w * 0.1, h * 0.7, w * 0.1, h * 0.1, w * 0.2, h * 0.2);
    path.cubicTo(w * 0.3, h * 0.3, w * 0.3, h * 0.6, w * 0.4, h * 0.5);
    path.cubicTo(w * 0.5, h * 0.4, w * 0.5, h * 0.2, w * 0.6, h * 0.3);
    path.cubicTo(w * 0.7, h * 0.4, w * 0.7, h * 0.8, w * 0.8, h * 0.7);
    path.cubicTo(w * 0.9, h * 0.6, w * 0.9, h * 0.1, w, h * 0.2);

    canvas.drawPath(path, paint);

    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
