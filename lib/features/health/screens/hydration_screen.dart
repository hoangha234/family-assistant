import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import '../cubit/hydration_cubit.dart';
import '../cubit/hydration_state.dart';
import '../services/hydration_service.dart';
import '../models/hydration_log_model.dart';

class HydrationScreen extends StatelessWidget {
  const HydrationScreen({super.key});

  // Colors
  static const Color primaryGreen = Color(0xFF006E36);
  static const Color primaryMint = Color(0xFF6DFE9C);
  static const Color background = Color(0xFFF7F9FB);
  static const Color surfaceWhite = Colors.white;
  static const Color textMain = Color(0xFF2C3437);
  static const Color textVariant = Color(0xFF596064);

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

  void _showAddWaterDialog(BuildContext context, String session) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<HydrationCubit>(),
        child: _AddWaterDialog(session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HydrationCubit(
        hydrationService: HydrationService(),
      ),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: background,
            appBar: AppBar(
              backgroundColor: background.withOpacity(0.8),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: primaryGreen),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Hydration',
                style: GoogleFonts.manrope(
                  color: primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.history, color: primaryGreen),
                  onPressed: () {
                    context.read<HydrationCubit>().loadRecentLogs();
                    _showHistoryModal(context);
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  _buildCircularProgress(),
                  const SizedBox(height: 40),
                  _buildSessionActionCards(context),
                  const SizedBox(height: 40),
                  _buildRecentLogsHeader(context),
                  const SizedBox(height: 16),
                  _buildRecentLogsList(),
                  const SizedBox(height: 32),
                  _buildProTip(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildCircularProgress() {
    return BlocBuilder<HydrationCubit, HydrationState>(
      builder: (context, state) {
        final progress = state.progress;
        final totalStr = (state.totalAmountToday / 1000).toStringAsFixed(1);
        final goalStr = (state.dailyGoal / 1000).toStringAsFixed(1);
        final percentStr = (progress * 100).toInt().toString();

        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: surfaceWhite,
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.08),
                      blurRadius: 50,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 230,
                height: 230,
                child: CustomPaint(
                  painter: HydrationProgressPainter(
                    progress: progress,
                    primaryColor: primaryGreen,
                    accentColor: primaryMint,
                    trackColor: const Color(0xFFEAEFF2),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${totalStr}L',
                    style: GoogleFonts.manrope(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: textMain,
                    ),
                  ),
                  Text(
                    '/ ${goalStr}L Goal',
                    style: const TextStyle(
                      color: textVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD3E4FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.water_drop, size: 12, color: Color(0xFF435368)),
                        const SizedBox(width: 4),
                        Text(
                          '$percentStr% DAILY GOAL',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF435368),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionActionCards(BuildContext context) {
    return BlocBuilder<HydrationCubit, HydrationState>(
      builder: (context, state) {
        final morningAmount = (state.getAmountForSession('Morning') / 1000).toStringAsFixed(1);
        final afterAmount = (state.getAmountForSession('Afternoon') / 1000).toStringAsFixed(1);
        final eveningAmount = (state.getAmountForSession('Evening') / 1000).toStringAsFixed(1);

        return Row(
          children: [
            _sessionCard(context, Icons.light_mode, 'Morning', '${morningAmount}L'),
            const SizedBox(width: 12),
            _sessionCard(context, Icons.wb_sunny, 'Afternoon', '${afterAmount}L'),
            const SizedBox(width: 12),
            _sessionCard(context, Icons.dark_mode, 'Evening', '${eveningAmount}L'),
          ],
        );
      },
    );
  }

  Widget _sessionCard(BuildContext context, IconData icon, String title, String amount) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showAddWaterDialog(context, title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textVariant)),
              const SizedBox(height: 8),
              Icon(icon, color: Colors.blueAccent.shade100, size: 24),
              const SizedBox(height: 4),
              Text(amount, style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentLogsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Recent Logs',
          style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.bold, color: textMain),
        ),
        TextButton(
          onPressed: () {
            context.read<HydrationCubit>().loadRecentLogs();
            _showHistoryModal(context);
          },
          child: const Text('View All', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildRecentLogsList() {
    return BlocBuilder<HydrationCubit, HydrationState>(
      builder: (context, state) {
        if (state.todayLogs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No logs yet for today. Stay hydrated!', style: TextStyle(color: textVariant)),
          );
        }

        final recentLogs = state.todayLogs.take(5).toList();

        return Column(
          children: recentLogs.map((log) {
            final timeStr = DateFormat('hh:mm a').format(log.timestamp);
            Color borderColor = primaryGreen;
            if (log.session == 'Afternoon') borderColor = primaryMint;
            if (log.session == 'Evening') borderColor = Colors.blueAccent.shade100;
            return _buildLogEntry('${log.amount}ml', '$timeStr • ${log.session}', borderColor);
          }).toList(),
        );
      },
    );
  }

  Widget _buildLogEntry(String amount, String time, Color borderColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: Color(0xFFD3E4FE), shape: BoxShape.circle),
            child: const Icon(Icons.water_drop, color: Color(0xFF435368)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(time, style: const TextStyle(color: textVariant, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.more_vert, color: Colors.black26),
        ],
      ),
    );
  }

  Widget _buildProTip() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE3E9ED),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('PRO TIP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                SizedBox(height: 8),
                Text(
                  'Staying hydrated improves focus and energy levels by 20% throughout the day.',
                  style: TextStyle(fontWeight: FontWeight.w500, height: 1.4),
                ),
              ],
            ),
          ),
          Icon(Icons.lightbulb_outline, size: 48, color: textMain.withOpacity(0.1)),
        ],
      ),
    );
  }
}

class HydrationProgressPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color accentColor;
  final Color trackColor;

  HydrationProgressPainter({
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 24.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [primaryColor, accentColor],
        // The SweepGradient behaves somewhat unpredictably for sweeping,
        // so we can use stops or just let it sweep entire circle and clip it with arc.
      )
      // Transform local coordinate system to the rect's bounds to make sweep look logical
      .createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final resolvedProgress = progress.isNaN || progress.isInfinite ? 0.0 : progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * resolvedProgress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _AddWaterDialog extends StatefulWidget {
  final String session;
  const _AddWaterDialog({required this.session});

  @override
  State<_AddWaterDialog> createState() => _AddWaterDialogState();
}

class _AddWaterDialogState extends State<_AddWaterDialog> {
  int _amount = 250;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Water (${widget.session})'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('How much water did you drink?', style: TextStyle(color: HydrationScreen.textVariant)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => setState(() => _amount = math.max(50, _amount - 50)),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('${_amount}ml', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => setState(() => _amount += 50),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _presetButton(100),
              _presetButton(250),
              _presetButton(500),
            ],
          )
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            context.read<HydrationCubit>().addWater(_amount, widget.session);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: HydrationScreen.primaryGreen,
            foregroundColor: Colors.white,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }

  Widget _presetButton(int amt) {
    return InkWell(
      onTap: () => setState(() => _amount = amt),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _amount == amt ? HydrationScreen.primaryGreen.withOpacity(0.1) : Colors.grey.shade100,
          border: Border.all(
            color: _amount == amt ? HydrationScreen.primaryGreen : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('${amt}ml'),
      ),
    );
  }
}

class _HistoryModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: HydrationScreen.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                '7 Days History',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: HydrationScreen.textMain,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<HydrationCubit, HydrationState>(
                  builder: (context, state) {
                    if (state.recentLogs.isEmpty) {
                      return const Center(child: Text('No history found.'));
                    }

                    // Group by day
                    final groupedLogs = <String, List<HydrationLog>>{};
                    for (var log in state.recentLogs) {
                      final dayStr = DateFormat('EEEE, MMM d').format(log.timestamp);
                      if (!groupedLogs.containsKey(dayStr)) {
                        groupedLogs[dayStr] = [];
                      }
                      groupedLogs[dayStr]!.add(log);
                    }

                    return ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: groupedLogs.length,
                      itemBuilder: (context, index) {
                        final dayStr = groupedLogs.keys.elementAt(index);
                        final logs = groupedLogs[dayStr]!;
                        final totalAmt = logs.fold(0, (s, l) => s + l.amount);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12, top: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(dayStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${totalAmt}ml', style: const TextStyle(color: HydrationScreen.primaryGreen, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            ...logs.map((log) {
                              final timeStr = DateFormat('hh:mm a').format(log.timestamp);
                              Color borderColor = HydrationScreen.primaryGreen;
                              if (log.session == 'Afternoon') borderColor = HydrationScreen.primaryMint;
                              if (log.session == 'Evening') borderColor = Colors.blueAccent.shade100;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border(left: BorderSide(color: borderColor, width: 4)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.water_drop, color: Color(0xFF435368), size: 20),
                                    const SizedBox(width: 12),
                                    Text('${log.amount}ml', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const Spacer(),
                                    Text('$timeStr • ${log.session}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  ],
                                ),
                              );
                            }).toList(),
                            const Divider(height: 24),
                          ],
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
