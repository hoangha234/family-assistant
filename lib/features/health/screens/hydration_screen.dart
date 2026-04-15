import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../cubit/hydration_cubit.dart';
import '../cubit/hydration_state.dart';
import '../services/hydration_service.dart';
import '../models/hydration_log_model.dart';
import '../services/notification_service.dart';

class HydrationScreen extends StatefulWidget {
  const HydrationScreen({super.key});

  @override
  State<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends State<HydrationScreen> {
  static const Color primaryGreen = Color(0xFF006E36);
  static const Color primaryMint = Color(0xFF6DFE9C);

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get background => isDark ? const Color(0xFF101822) : const Color(0xFFF7F9FB);
  Color get surfaceWhite => isDark ? const Color(0xFF1A2737) : Colors.white;
  Color get textMain => isDark ? Colors.white : const Color(0xFF2C3437);
  Color get textVariant => isDark ? Colors.grey[400]! : const Color(0xFF596064);
  Color get cardBg => isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F4F7);

  @override
  void initState() {
    super.initState();
    _requestNotificationPermissions();
  }

  Future<void> _requestNotificationPermissions() async {
    await NotificationService.requestPermissions();
  }

  void _showHistoryModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<HydrationCubit>(),
        child: _HistoryModal(),
      ),
    );
  }

  Future<void> _editStartTime(
    BuildContext context,
    DateTime currentStartTime,
  ) async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentStartTime),
    );

    if (newTime != null && context.mounted) {
      if (newTime.hour >= 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "It's too late to start now! Please choose a time from 7:59 AM or earlier to have enough time to drink all your water for the day.",
            ),
            backgroundColor: Color(0xFFC62828),
          ),
        );
        return;
      }

      final now = DateTime.now();
      final updatedStartTime = DateTime(
        now.year,
        now.month,
        now.day,
        newTime.hour,
        newTime.minute,
      );
      context.read<HydrationCubit>().updateStartTime(updatedStartTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HydrationCubit(hydrationService: HydrationService()),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: background,
            appBar: _buildAppBar(context),
            body: BlocBuilder<HydrationCubit, HydrationState>(
              builder: (context, state) {
                if (state.status == HydrationStatus.loading ||
                    state.status == HydrationStatus.initial) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryGreen),
                  );
                }

                if (state.errorMessage != null &&
                    state.errorMessage!.isNotEmpty) {
                  return Center(child: Text('Error: ${state.errorMessage}'));
                }

                final plan = state.todayPlan;
                if (plan == null)
                  return const Center(child: Text('No plan found.'));

                final drankCups = state.currentLevel;
                final totalGoal = state.dailyGoal;
                final perCup = state.waterPerCup;
                final canConfirmDrink = context.read<HydrationCubit>().canConfirmDrink;

                DateTime? nextSession;
                if (drankCups < 5) {
                  nextSession = plan.sessions[drankCups];
                }

                return RefreshIndicator(
                  onRefresh: () => context.read<HydrationCubit>().refresh(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      _buildBottleVisual(drankCups, totalGoal, perCup),
                      const SizedBox(height: 40),
                      _buildSessionProgress(plan.sessions, drankCups),
                      const SizedBox(height: 32),
                      _buildHydrationPlanCard(
                        context,
                        plan.startTime,
                        plan.sessions,
                      ),
                      const SizedBox(height: 40),
                      _buildDrunkButton(context, drankCups, canConfirmDrink, nextSession),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: background.withOpacity(0.8),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: textMain),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Hydration Schedule',
        style: GoogleFonts.manrope(
          color: textMain,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.history, color: textMain),
          onPressed: () {
            context.read<HydrationCubit>().loadRecentLogs();
            _showHistoryModal(context);
          },
        ),
        const Padding(
          padding: EdgeInsets.only(right: 16),
          child: CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage('https://picsum.photos/200'),
          ),
        ),
      ],
    );
  }

  Widget _buildBottleVisual(int drankCups, int totalGoal, int perCup) {
    final double targetHeightFactor = (drankCups / 5).clamp(0.0, 1.0);

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -20,
            top: 0,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: primaryMint.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            width: 180,
            height: 320,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(64),
                bottom: Radius.circular(40),
              ),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFDCE4E8), width: 6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(58),
                bottom: Radius.circular(34),
              ),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: targetHeightFactor),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOutBack,
                    builder: (context, value, child) {
                      return FractionallySizedBox(
                        heightFactor: value.clamp(0.0, double.infinity),
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryGreen, primaryMint],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Column(
                    children: List.generate(5, (index) {
                      return Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: index == 0
                                ? null
                                : Border(
                                    top: BorderSide(
                                      color: Colors.white.withOpacity(0.4),
                                    ),
                                  ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 140,
            right: -30,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceWhite.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${drankCups * perCup}',
                          style: GoogleFonts.manrope(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: primaryGreen,
                          ),
                        ),
                        TextSpan(
                          text: 'ml',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'of ${totalGoal}ml',
                    style: TextStyle(
                      fontSize: 10,
                      color: textVariant,
                      letterSpacing: 1.2,
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

  Widget _buildSessionProgress(List<DateTime> sessions, int drankCups) {
    if (sessions.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (index) {
        bool isCompleted = index < drankCups;
        String timeStr = index < sessions.length
            ? DateFormat('HH:mm').format(sessions[index])
            : '--:--';

        return Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCompleted ? primaryMint : Colors.transparent,
                shape: BoxShape.circle,
                border: isCompleted
                    ? null
                    : Border.all(color: textVariant.withOpacity(0.3), width: 2),
              ),
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.water_drop,
                size: 20,
                color: isCompleted
                    ? primaryGreen
                    : textVariant.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isCompleted ? FontWeight.bold : FontWeight.w500,
                color: isCompleted ? primaryGreen : textVariant,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildHydrationPlanCard(
    BuildContext context,
    DateTime startTime,
    List<DateTime> sessions,
  ) {
    bool extendsNextDay = false;
    if (sessions.isNotEmpty) {
      final lastSession = sessions.last;
      if (lastSession.day != startTime.day) {
        extendsNextDay = true;
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hydration Plan',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textMain,
                ),
              ),
              GestureDetector(
                onTap: () => _editStartTime(context, startTime),
                child: const Icon(Icons.edit, color: primaryGreen, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceWhite,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFD3E4FE),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.schedule, color: isDark ? Colors.blue[200] : const Color(0xFF435368)),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Time',
                      style: TextStyle(fontSize: 12, color: textVariant),
                    ),
                    Text(
                      DateFormat('hh:mm a').format(startTime),
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.notifications_active,
                color: primaryGreen.withOpacity(0.5),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Reminders every 4 hours until the bottle is full.',
                  style: TextStyle(
                    fontSize: 13,
                    color: textVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (extendsNextDay) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.nightlight_round,
                    color: Colors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: Your final schedule extends into the next calendar day.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDrunkButton(BuildContext context, int drankCups, bool canConfirmDrink, DateTime? nextSession) {
    bool isDone = drankCups >= 5;
    bool isDisabled = isDone || !canConfirmDrink;

    return Column(
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isDisabled ? 0.5 : 1.0,
          child: Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              color: isDone ? Colors.grey.shade300 : null,
              gradient: isDone ? null : const LinearGradient(colors: [primaryGreen, primaryMint]),
              borderRadius: BorderRadius.circular(32),
              boxShadow: isDone
                  ? []
                  : [
                      BoxShadow(
                        color: primaryGreen.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
            ),
            child: ElevatedButton.icon(
              onPressed: isDisabled
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      context.read<HydrationCubit>().confirmDrink();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                disabledForegroundColor: Colors.grey.shade800,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              ),
              icon: isDone ? const Icon(Icons.check_circle) : const Icon(Icons.add_circle, color: Colors.white),
              label: Text(
                isDone ? 'Goal Reached!' : 'I\'ve Drunk 400ml',
                style: TextStyle(
                  color: isDone ? Colors.grey.shade700 : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
        if (!isDone && !canConfirmDrink && nextSession != null) ...[
          const SizedBox(height: 12),
          Text(
            'Mốc uống nước tiếp theo: ${DateFormat('hh:mm a').format(nextSession)}',
            style: TextStyle(color: textVariant, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }
}

class _HistoryModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF101822) : const Color(0xFFF7F9FB);
    final textM = isDark ? Colors.white : const Color(0xFF2C3437);
    final textV = isDark ? Colors.grey[400]! : const Color(0xFF596064);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        builder: (_, controller) {
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                '30 Days History',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textM,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<HydrationCubit, HydrationState>(
                  builder: (context, state) {
                    if (state.recentLogs.isEmpty) {
                      return const Center(child: Text('No history found.'));
                    }

                    return ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      itemCount: state.recentLogs.length,
                      itemBuilder: (context, index) {
                        final log = state.recentLogs[index];
                        final dayStr = DateFormat(
                          'EEEE, MMM d',
                        ).format(log.date);
                        final totalAmt = log.currentLevel * state.waterPerCup;
                        final percent = (log.currentLevel / 5 * 100).toInt();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A2737) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: const Border(
                              left: BorderSide(
                                color: _HydrationScreenState.primaryGreen,
                                width: 4,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFD3E4FE),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.water_drop,
                                  color: isDark ? Colors.blue[200] : const Color(0xFF435368),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dayStr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Achieved $percent% of goal',
                                      style: TextStyle(
                                        color: textV,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${totalAmt}ml',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _HydrationScreenState.primaryGreen,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
