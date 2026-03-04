import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/meal_service.dart';

class MealHistoryScreen extends StatefulWidget {
  const MealHistoryScreen({super.key});

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  final MealService _mealService = MealService();
  List<MealPlanDocument>? _history;
  bool _isLoading = true;
  String? _error;

  final Color primaryColor = const Color(0xFF13EC80);
  final Color bgLight = const Color(0xFFF8F9FA);
  final Color bgDark = const Color(0xFF102219);
  final Color textDark = const Color(0xFF111814);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _mealService.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final history = await _mealService.getMealHistory(limit: 10);
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? bgDark : bgLight;
    final textColor = isDarkMode ? Colors.white : textDark;
    final cardColor = isDarkMode ? Colors.grey[850]! : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Meal History',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(isDarkMode, textColor, cardColor),
    );
  }

  Widget _buildBody(bool isDarkMode, Color textColor, Color cardColor) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Failed to load history',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadHistory,
              child: Text(
                'Try Again',
                style: GoogleFonts.manrope(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_history == null || _history!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: primaryColor.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              'No meal history yet',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start planning your meals to see history',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history!.length,
        itemBuilder: (context, index) {
          final mealPlan = _history![index];
          return _buildHistoryCard(mealPlan, isDarkMode, textColor, cardColor);
        },
      ),
    );
  }

  Widget _buildHistoryCard(
    MealPlanDocument mealPlan,
    bool isDarkMode,
    Color textColor,
    Color cardColor,
  ) {
    // Parse date
    final dateParts = mealPlan.date.split('-');
    final year = int.tryParse(dateParts[0]) ?? 2024;
    final month = int.tryParse(dateParts[1]) ?? 1;
    final day = int.tryParse(dateParts[2]) ?? 1;
    final date = DateTime(year, month, day);

    // Format date display
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekday = weekdays[date.weekday - 1];
    final monthName = months[date.month - 1];
    final dateDisplay = '$weekday, $monthName ${date.day}';

    // Check if today
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

    return GestureDetector(
      onTap: () {
        // Navigate back with selected date
        Navigator.pop(context, date);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isToday ? primaryColor : primaryColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isToday ? 'Today' : dateDisplay,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isToday ? textDark : primaryColor,
                        ),
                      ),
                    ),
                    if (!isToday) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${date.year}',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      '${mealPlan.totalCalories} kcal',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Meals
            _buildMealRow(
              'Breakfast',
              mealPlan.meals['breakfast']?.name,
              Icons.wb_sunny_outlined,
              Colors.orange,
              textColor,
              isDarkMode,
            ),
            const SizedBox(height: 8),
            _buildMealRow(
              'Lunch',
              mealPlan.meals['lunch']?.name,
              Icons.wb_cloudy_outlined,
              Colors.blue,
              textColor,
              isDarkMode,
            ),
            const SizedBox(height: 8),
            _buildMealRow(
              'Dinner',
              mealPlan.meals['dinner']?.name,
              Icons.nightlight_outlined,
              Colors.purple,
              textColor,
              isDarkMode,
            ),
            const SizedBox(height: 12),
            // View details hint
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Tap to view',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 12, color: primaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealRow(
    String type,
    String? mealName,
    IconData icon,
    Color iconColor,
    Color textColor,
    bool isDarkMode,
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            type,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            mealName ?? '—',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: mealName != null ? FontWeight.w600 : FontWeight.normal,
              color: mealName != null ? textColor : Colors.grey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

