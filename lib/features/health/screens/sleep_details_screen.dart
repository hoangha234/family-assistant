import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../cubit/sleep_cubit.dart';
import '../cubit/sleep_state.dart';
import '../models/sleep_data_model.dart';

class SleepDetailsScreen extends StatelessWidget {
  const SleepDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SleepCubit(),
      child: const _SleepDetailsView(),
    );
  }
}

class _SleepDetailsView extends StatefulWidget {
  const _SleepDetailsView();

  @override
  State<_SleepDetailsView> createState() => _SleepDetailsViewState();
}

class _SleepDetailsViewState extends State<_SleepDetailsView> {
  static const Color primaryGreen = Color(0xFF006E36);
  static const Color primaryMint = Color(0xFF6DFE9C);

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get background => isDark ? const Color(0xFF101822) : const Color(0xFFF7F9FB);
  Color get surfaceWhite => isDark ? const Color(0xFF1A2737) : Colors.white;
  Color get textMain => isDark ? Colors.white : const Color(0xFF2C3437);
  Color get textVariant => isDark ? Colors.grey[400]! : const Color(0xFF596064);

  bool _dialogShown = false;

  void _showSleepScheduleBottomSheet(BuildContext context) async {
    final cubit = context.read<SleepCubit>();
    TimeOfDay initialBedtime = const TimeOfDay(hour: 22, minute: 0);
    TimeOfDay initialWakeup = const TimeOfDay(hour: 6, minute: 0);
    
    final currentData = cubit.state.sleepData;
    if (currentData != null) {
      initialBedtime = TimeOfDay.fromDateTime(currentData.bedtime);
      initialWakeup = TimeOfDay.fromDateTime(currentData.wakeup);
    }

    TimeOfDay? selectedBedtime = await showTimePicker(
      context: context,
      initialTime: initialBedtime,
      helpText: 'Select Bedtime',
    );

    if (selectedBedtime == null) return;

    if (!context.mounted) return;

    TimeOfDay? selectedWakeup = await showTimePicker(
      context: context,
      initialTime: initialWakeup,
      helpText: 'Select Wake up time',
    );

    if (selectedWakeup == null) return;

    await cubit.saveSchedule(selectedBedtime, selectedWakeup);
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sleep Quality'),
          content: const Text('Bạn có ngủ đủ giấc như đã đặt không?'),
          actions: [
            TextButton(
              onPressed: () {
                context.read<SleepCubit>().confirmSleep('Poor Quality');
                Navigator.pop(dialogContext);
              },
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<SleepCubit>().confirmSleep('Good Quality');
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
              child: const Text('Yes', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SleepCubit, SleepState>(
      listener: (context, state) {
        if (state.status == SleepStatus.loaded && !_dialogShown) {
          if (context.read<SleepCubit>().shouldShowConfirmationDialog()) {
            _dialogShown = true;
            // Delay dialog slightly so build finishes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showConfirmationDialog(context);
            });
          }
        }
        if (state.status == SleepStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Error occurred')),
          );
        }
      },
      builder: (context, state) {
        final data = state.sleepData;
        final bool isLoading = state.status == SleepStatus.loading || state.status == SleepStatus.initial;
        
        final durationText = data?.formattedSleepDuration ?? '0h 00m';
        final qualityTag = data?.qualityTag ?? 'No Data';

        final bedtimeText = data != null ? DateFormat('HH:mm').format(data.bedtime) : '--:--';
        final wakeupText = data != null ? DateFormat('HH:mm').format(data.wakeup) : '--:--';

        return Scaffold(
          backgroundColor: background,
          appBar: _buildAppBar(context),
          body: isLoading
              ? const Center(child: CircularProgressIndicator(color: primaryGreen))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroCard(durationText, qualityTag, state.history7Days),
                      const SizedBox(height: 32),
                      _buildSleepStagesSection(state),
                      const SizedBox(height: 32),
                      _buildDataGrid(bedtimeText, wakeupText),
                      const SizedBox(height: 32),
                      _buildActionButton(context),
                      const SizedBox(height: 32),
                      _buildSleepHistorySection(state.history30Days),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: primaryGreen),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Sleep Details',
        style: GoogleFonts.manrope(
          color: textMain,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.settings, color: primaryGreen),
          onSelected: (value) {
            if (value == 'delete') {
              context.read<SleepCubit>().deleteTodayData();
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('Delete today\'s data'),
              ),
            ];
          },
        ),
      ],
    );
  }

  Widget _buildHeroCard(String durationText, String qualityTag, List<SleepData> history7Days) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: primaryMint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              qualityTag,
              style: const TextStyle(
                color: Color(0xFF004A22),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            durationText,
            style: GoogleFonts.manrope(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: textMain,
            ),
          ),
          Text(
            'Time Asleep',
            style: TextStyle(color: textVariant, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final dataIndex = index - (7 - history7Days.length);
                if (dataIndex < 0) {
                  return _bar(0.05, Colors.grey.withOpacity(0.1));
                }
                final data = history7Days[dataIndex];
                final duration = data.wakeup.difference(data.bedtime);
                final factor = (duration.inMinutes / 600).clamp(0.05, 1.0);
                
                final isToday = dataIndex == history7Days.length - 1;
                final color = isToday ? primaryGreen : primaryMint.withOpacity(0.8);
                return _bar(factor, color);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(double heightFactor, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        height: 120 * heightFactor,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildSleepStagesSection(SleepState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sleep Stages',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textMain,
              ),
            ),
            Text(
              'Last Night',
              style: TextStyle(fontSize: 12, color: textVariant),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surfaceWhite,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: 6,
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 5),
                            FlSpot(1, 1),
                            FlSpot(2, 4),
                            FlSpot(3, 2),
                            FlSpot(4, 5),
                            FlSpot(5, 1),
                            FlSpot(6, 6),
                          ],
                          isCurved: true,
                          color: primaryMint,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: primaryGreen.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                children: [
                  _legendItem('Deep Sleep', state.deepSleepFormatted, primaryGreen),
                  _legendItem('REM Sleep', state.remSleepFormatted, primaryMint),
                  _legendItem('Light Sleep', state.lightSleepFormatted, Colors.grey.shade300),
                  _legendItem('Awake', state.awakeFormatted, isDark ? const Color(0xFF0F172A) : const Color(0xFFD3E4FE)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendItem(String label, String time, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Text(time, style: TextStyle(fontSize: 10, color: textVariant)),
          ],
        ),
      ],
    );
  }

  Widget _buildDataGrid(String bedtimeText, String wakeupText) {
    return Row(
      children: [
        Expanded(child: _dataCard(Icons.bedtime, 'Bedtime', bedtimeText)),
        const SizedBox(width: 16),
        Expanded(child: _dataCard(Icons.wb_sunny, 'Wake up', wakeupText)),
      ],
    );
  }

  Widget _dataCard(IconData icon, String title, String time) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.white.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryGreen, size: 24),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 12, color: textVariant)),
          Text(
            time,
            style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryGreen, primaryMint],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _showSleepScheduleBottomSheet(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        ),
        child: const Text(
          'Sleep Schedule',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSleepHistorySection(List<SleepData> history) {
    if (history.isEmpty) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sleep History (Past 30 Days)',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textMain,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = history[index];
            final dateText = DateFormat('dd MMM').format(data.date);
            final durationText = data.formattedSleepDuration;
            final qualityTag = data.qualityTag;
            
            final duration = data.wakeup.difference(data.bedtime);
            final hours = duration.inMinutes / 60;
            
            final isGood = qualityTag.toLowerCase().contains('good');
            final color = isGood ? primaryGreen : Colors.grey;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceWhite,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      dateText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          durationText,
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            color: textMain,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (hours / 10).clamp(0.0, 1.0),
                            backgroundColor: Colors.grey.withOpacity(0.1),
                            color: color,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      qualityTag == 'N/A' ? 'No Data' : qualityTag,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

