import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../cubit/shopping_schedule_cubit.dart';
import '../services/shopping_service.dart';
import 'add_schedule_screen.dart';

class ShoppingScheduleScreen extends StatelessWidget {
  const ShoppingScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ShoppingScheduleCubit()..initialize(),
      child: const ShoppingScheduleView(),
    );
  }
}

class ShoppingScheduleView extends StatefulWidget {
  const ShoppingScheduleView({super.key});

  @override
  State<ShoppingScheduleView> createState() => _ShoppingScheduleViewState();
}

class _ShoppingScheduleViewState extends State<ShoppingScheduleView> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get bgLight => isDark ? const Color(0xFF101822) : const Color(0xFFF8F9FA);
  Color get textDark => isDark ? Colors.white : const Color(0xFF111518);
  Color get textMuted => isDark ? Colors.grey[400]! : const Color(0xFF60798A);
  Color get cardBg => isDark ? const Color(0xFF1A2737) : Colors.white;
  Color get dividerColor => isDark ? const Color(0xFF334155) : Colors.grey.shade100;
  static const Color primaryColor = Color(0xFF0B84DA);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShoppingScheduleCubit, ShoppingScheduleState>(
      listener: (context, state) {
        if (state.hasError && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
          context.read<ShoppingScheduleCubit>().clearError();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: bgLight,
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 90),
                  child: Column(
                    children: [
                      _buildHeader(context),
                      _buildSegmentedControl(context, state),
                      Expanded(
                        child: _buildContent(context, state),
                      ),
                    ],
                  ),
                ),
                // FAB
                Positioned(
                  bottom: 100,
                  right: 24,
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddScheduleScreen(),
                        ),
                      );
                      if (context.mounted) {
                        context.read<ShoppingScheduleCubit>().refresh();
                      }
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: bgLight.withValues(alpha: 0.9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              children: [
                Icon(Icons.chevron_left, size: 28, color: textDark),
                const SizedBox(width: 4),
                Text(
                  'Back',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Shopping Schedule',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl(BuildContext context, ShoppingScheduleState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202C39) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabItem(context, 'Pending', 0, state.selectedTab == 0, state.pendingSchedules.length),
          _buildTabItem(context, 'Completed', 1, state.selectedTab == 1, state.completedSchedules.length),
        ],
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, String title, int index, bool isSelected, int count) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<ShoppingScheduleCubit>().setTab(index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? const Color(0xFF334155) : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2)]
                : [],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? textDark : textMuted,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ShoppingScheduleState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final schedules = state.selectedTab == 0
        ? state.pendingSchedules
        : state.completedSchedules;

    if (schedules.isEmpty) {
      return _buildEmptyState(state.selectedTab == 0);
    }

    return RefreshIndicator(
      onRefresh: () => context.read<ShoppingScheduleCubit>().refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: schedules.length,
        itemBuilder: (context, index) {
          final schedule = schedules[index];
          return _buildScheduleCard(context, schedule, state);
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isPendingTab) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPendingTab ? Icons.shopping_cart_outlined : Icons.check_circle_outline,
            size: 64,
            color: textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isPendingTab ? 'No pending schedules' : 'No completed schedules',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPendingTab ? 'Tap + to add a new schedule' : 'Completed purchases will appear here',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: textMuted.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context, ShoppingSchedule schedule, ShoppingScheduleState state) {
    final isProcessing = state.isScheduleProcessing(schedule.id);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: schedule.status == ScheduleStatus.failed
              ? Colors.red.withValues(alpha: 0.3)
              : dividerColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              _buildCategoryIcon(schedule.category),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            schedule.title,
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Payment Mode Badge
                        _buildPaymentModeBadge(schedule.paymentMode),
                        const SizedBox(width: 4),
                        // Status Badge
                        _buildStatusBadge(schedule.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${schedule.category} • ${DateFormat('MMM d, y').format(schedule.dueDate)}',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                currencyFormat.format(schedule.amount),
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),

          // Monthly Repeat Indicator
          if (schedule.isMonthly) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.repeat, size: 14, color: Colors.orange[700]),
                const SizedBox(width: 4),
                Text(
                  'Repeats Monthly',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ],

          // Action Buttons (only for pending schedules)
          if (schedule.status == ScheduleStatus.pending) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildActionButtons(context, schedule, isProcessing),
          ],

          // Failed schedule retry action
          if (schedule.status == ScheduleStatus.failed) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildFailedActions(context, schedule, isProcessing),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(String category) {
    IconData icon;
    Color color;
    Color bgColor;

    switch (category.toLowerCase()) {
      case 'groceries':
        icon = Icons.shopping_cart;
        color = primaryColor;
        bgColor = primaryColor.withValues(alpha: 0.1);
        break;
      case 'health':
        icon = Icons.medical_services;
        color = Colors.red;
        bgColor = Colors.red.withValues(alpha: 0.1);
        break;
      case 'home':
        icon = Icons.home;
        color = Colors.green;
        bgColor = Colors.green.withValues(alpha: 0.1);
        break;
      case 'tech':
        icon = Icons.devices;
        color = Colors.purple;
        bgColor = Colors.purple.withValues(alpha: 0.1);
        break;
      default:
        icon = Icons.category;
        color = Colors.grey;
        bgColor = Colors.grey.withValues(alpha: 0.1);
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildPaymentModeBadge(PaymentMode mode) {
    final isAuto = mode == PaymentMode.automatic;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAuto ? Colors.blue.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isAuto ? 'AUTO' : 'MANUAL',
        style: GoogleFonts.manrope(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: isAuto ? Colors.blue[700] : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ScheduleStatus status) {
    Color color;
    Color bgColor;
    String text;

    switch (status) {
      case ScheduleStatus.pending:
        color = Colors.orange[700]!;
        bgColor = Colors.orange.withValues(alpha: 0.1);
        text = 'PENDING';
        break;
      case ScheduleStatus.paid:
        color = Colors.green[700]!;
        bgColor = Colors.green.withValues(alpha: 0.1);
        text = 'PAID';
        break;
      case ScheduleStatus.failed:
        color = Colors.red[700]!;
        bgColor = Colors.red.withValues(alpha: 0.1);
        text = 'FAILED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ShoppingSchedule schedule, bool isProcessing) {
    // Manual schedules: Show "Mark as Purchased" button
    if (schedule.paymentMode == PaymentMode.manual) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: isProcessing
              ? null
              : () => _showMarkAsPurchasedDialog(context, schedule),
          icon: isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_circle, size: 18),
          label: Text(isProcessing ? 'Processing...' : 'Mark as Purchased'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }

    // Automatic schedules: Status-only display (no manual action)
    return Row(
      children: [
        Icon(Icons.schedule, size: 16, color: textMuted),
        const SizedBox(width: 6),
        Text(
          'Automatic payment scheduled',
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildFailedActions(BuildContext context, ShoppingSchedule schedule, bool isProcessing) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: Colors.red[700]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Payment failed - insufficient balance',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: isProcessing
              ? null
              : () => context.read<ShoppingScheduleCubit>().resetFailedSchedule(schedule.id),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: Text(
            'Retry',
            style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _showMarkAsPurchasedDialog(BuildContext context, ShoppingSchedule schedule) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Mark as Purchased',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Confirm that you have purchased "${schedule.title}"?\n\nThis will mark the schedule as completed.',
          style: GoogleFonts.manrope(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ShoppingScheduleCubit>().markAsPaidManually(schedule.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
