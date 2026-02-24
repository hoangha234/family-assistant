import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../cubit/report_cubit.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReportCubit()..initialize(),
      child: const ReportView(),
    );
  }
}

class ReportView extends StatelessWidget {
  const ReportView({super.key});

  final Color primaryColor = const Color(0xFF0694F9);
  final Color bgLight = const Color(0xFFF5F7F8);
  final Color bgDark = const Color(0xFF0F1B23);
  final Color textDark = const Color(0xFF111518);

  final Color colorUtilities = const Color(0xFF38BDF8);
  final Color colorEntertainment = const Color(0xFF0EA5E9);
  final Color colorHealth = const Color(0xFF7DD3FC);
  final Color colorEducation = const Color(0xFFBAE6FD);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? bgDark : bgLight;
    final cardColor = isDarkMode ? const Color(0xFF111827) : Colors.white;
    final textColor = isDarkMode ? Colors.white : textDark;

    return BlocBuilder<ReportCubit, ReportState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    children: [
                      _buildHeader(context, textColor),
                      Expanded(
                        child: state.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildSegmentedControl(context, state, isDarkMode),
                              _buildDonutChartSection(state, cardColor, textColor, isDarkMode),
                              _buildCategoryBreakdown(state, cardColor, textColor, isDarkMode),
                              const SizedBox(height: 24),
                            ],
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
      },
    );
  }

  Widget _buildHeader(BuildContext context, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleButton(Icons.arrow_back, textColor),
          Text(
            'Financial Report',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          _buildCircleButton(Icons.share, textColor),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildSegmentedControl(BuildContext context, ReportState state, bool isDarkMode) {
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
          children: ['Week', 'Month', 'Year'].map((timeframe) {
            final isSelected = state.selectedTimeframe.displayName == timeframe;
            return Expanded(
              child: GestureDetector(
                onTap: () => context.read<ReportCubit>().setTimeframeString(timeframe),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? (isDarkMode ? primaryColor : Colors.white) 
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
                      fontWeight: FontWeight.w600,
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

  Widget _buildDonutChartSection(ReportState state, Color cardColor, Color textColor, bool isDarkMode) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final totalSpentStr = formatter.format(state.totalSpent);

    // Generate chart sections from category reports
    final colors = [primaryColor, colorUtilities, colorEntertainment, colorHealth, colorEducation];
    final sections = state.categoryReports.take(5).toList().asMap().entries.map((entry) {
      final index = entry.key;
      final report = entry.value;
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: report.percentage,
        title: '',
        radius: 25,
      );
    }).toList();

    // If no data, show empty chart
    if (sections.isEmpty) {
      sections.add(PieChartSectionData(
        color: Colors.grey[300]!,
        value: 100,
        title: '',
        radius: 25,
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
            )
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 70,
                      startDegreeOffset: -90,
                      sections: sections,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'TOTAL SPENT',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[500],
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalSpentStr,
                          style: GoogleFonts.manrope(
                            fontSize: 24,
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
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: state.categoryReports.take(5).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final report = entry.value;
                return _buildLegendItem(
                  colors[index % colors.length],
                  report.category.length > 8 ? '${report.category.substring(0, 8)}.' : report.category,
                  isDarkMode,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text, bool isDarkMode) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(ReportState state, Color cardColor, Color textColor, bool isDarkMode) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final colors = [primaryColor, colorUtilities, colorEntertainment, colorHealth, colorEducation];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Breakdown',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          if (state.categoryReports.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'No expenses for this period',
                  style: GoogleFonts.manrope(color: Colors.grey),
                ),
              ),
            )
          else
            ...state.categoryReports.asMap().entries.map((entry) {
              final index = entry.key;
              final report = entry.value;
              final color = colors[index % colors.length];
              final icon = _getCategoryIcon(report.category);

              String trendStr;
              Color trendColor;
              switch (report.trend) {
                case TrendDirection.up:
                  trendStr = '↑ ${report.trendPercentage.abs().toStringAsFixed(1)}%';
                  trendColor = Colors.red; // Up spending is bad
                  break;
                case TrendDirection.down:
                  trendStr = '↓ ${report.trendPercentage.abs().toStringAsFixed(1)}%';
                  trendColor = Colors.green; // Down spending is good
                  break;
                case TrendDirection.stable:
                  trendStr = 'Stable';
                  trendColor = Colors.grey;
                  break;
              }

              return _buildCategoryItem(
                icon: icon,
                color: color,
                title: report.category,
                subtitle: '${report.percentage.toStringAsFixed(0)}% of budget',
                amount: formatter.format(report.amount),
                trend: trendStr,
                trendColor: trendColor,
                cardColor: cardColor,
                textColor: textColor,
              );
            }),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'rent':
      case 'housing':
        return Icons.home;
      case 'shopping':
        return Icons.shopping_bag;
      case 'health':
      case 'healthcare':
        return Icons.medical_services;
      case 'groceries':
        return Icons.shopping_basket;
      case 'entertainment':
        return Icons.movie;
      case 'utilities':
        return Icons.bolt;
      case 'education':
        return Icons.school;
      default:
        return Icons.category;
    }
  }

  Widget _buildCategoryItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String amount,
    required String trend,
    required Color trendColor,
    required Color cardColor,
    required Color textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 2)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                  Text(subtitle, style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
              Text(trend, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: trendColor)),
            ],
          ),
        ],
      ),
    );
  }




}
