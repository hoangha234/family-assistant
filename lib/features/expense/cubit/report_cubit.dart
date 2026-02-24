import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';

part 'report_state.dart';

class ReportCubit extends Cubit<ReportState> {
  final ExpenseService _expenseService;

  ReportCubit({ExpenseService? expenseService})
      : _expenseService = expenseService ?? ExpenseService(),
        super(const ReportState());

  /// Initialize and load report data
  void initialize() {
    loadReport();
  }

  /// Set timeframe and reload data
  void setTimeframe(ReportTimeframe timeframe) {
    emit(state.copyWith(selectedTimeframe: timeframe));
    loadReport();
  }

  /// Legacy method for string timeframe
  void setTimeframeString(String timeframe) {
    final tf = ReportTimeframe.values.firstWhere(
      (e) => e.displayName == timeframe,
      orElse: () => ReportTimeframe.month,
    );
    setTimeframe(tf);
  }

  /// Load report data based on selected timeframe
  Future<void> loadReport() async {
    emit(state.copyWith(status: ReportCubitStatus.loading, clearError: true));

    try {
      final now = DateTime.now();
      List<Expense> currentExpenses;
      List<Expense> previousExpenses;

      switch (state.selectedTimeframe) {
        case ReportTimeframe.week:
          // Get start of current week (Monday)
          final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
          final previousWeekStart = currentWeekStart.subtract(const Duration(days: 7));

          currentExpenses = await _expenseService.fetchExpensesByWeek(currentWeekStart);
          previousExpenses = await _expenseService.fetchExpensesByWeek(previousWeekStart);
          break;

        case ReportTimeframe.month:
          final currentMonth = DateTime(now.year, now.month, 1);
          final previousMonth = DateTime(now.year, now.month - 1, 1);

          currentExpenses = await _expenseService.fetchExpensesByMonth(currentMonth);
          previousExpenses = await _expenseService.fetchExpensesByMonth(previousMonth);
          break;

        case ReportTimeframe.year:
          currentExpenses = await _expenseService.fetchExpensesByYear(now.year);
          previousExpenses = await _expenseService.fetchExpensesByYear(now.year - 1);
          break;
      }

      _processReportData(currentExpenses, previousExpenses);
    } catch (e) {
      emit(state.copyWith(
        status: ReportCubitStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Process report data and calculate statistics
  void _processReportData(List<Expense> current, List<Expense> previous) {
    // Filter only expenses (not income)
    final currentExpensesOnly = current.where((e) => e.type == ExpenseType.expense).toList();
    final previousExpensesOnly = previous.where((e) => e.type == ExpenseType.expense).toList();

    // Calculate totals
    final totalSpent = currentExpensesOnly.fold(0.0, (sum, e) => sum + e.amount);
    final previousTotalSpent = previousExpensesOnly.fold(0.0, (sum, e) => sum + e.amount);

    // Calculate category totals for current period
    final categoryTotals = <String, double>{};
    for (final expense in currentExpensesOnly) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0.0) + expense.amount;
    }

    // Calculate category totals for previous period
    final previousCategoryTotals = <String, double>{};
    for (final expense in previousExpensesOnly) {
      previousCategoryTotals[expense.category] =
          (previousCategoryTotals[expense.category] ?? 0.0) + expense.amount;
    }

    // Build category reports with trends
    final categoryReports = <CategoryReport>[];
    for (final entry in categoryTotals.entries) {
      final percentage = totalSpent > 0 ? (entry.value / totalSpent) * 100 : 0.0;
      final previousAmount = previousCategoryTotals[entry.key] ?? 0.0;

      final trend = _calculateTrend(entry.value, previousAmount);
      final trendPercentage = _calculateTrendPercentage(entry.value, previousAmount);

      categoryReports.add(CategoryReport(
        category: entry.key,
        amount: entry.value,
        percentage: percentage,
        trend: trend,
        trendPercentage: trendPercentage,
      ));
    }

    // Sort by amount descending
    categoryReports.sort((a, b) => b.amount.compareTo(a.amount));

    // Calculate overall trend
    final overallTrend = _calculateTrend(totalSpent, previousTotalSpent);
    final overallTrendPercentage = _calculateTrendPercentage(totalSpent, previousTotalSpent);

    emit(state.copyWith(
      status: ReportCubitStatus.loaded,
      totalSpent: totalSpent,
      previousTotalSpent: previousTotalSpent,
      categoryReports: categoryReports,
      overallTrend: overallTrend,
      overallTrendPercentage: overallTrendPercentage,
    ));
  }

  /// Calculate trend direction
  TrendDirection _calculateTrend(double current, double previous) {
    if (previous == 0) {
      return current > 0 ? TrendDirection.up : TrendDirection.stable;
    }
    final change = ((current - previous) / previous) * 100;
    if (change > 5) return TrendDirection.up;
    if (change < -5) return TrendDirection.down;
    return TrendDirection.stable;
  }

  /// Calculate trend percentage
  double _calculateTrendPercentage(double current, double previous) {
    if (previous == 0) return current > 0 ? 100.0 : 0.0;
    return ((current - previous) / previous) * 100;
  }

  /// Clear error
  void clearError() {
    emit(state.copyWith(clearError: true));
  }
}
