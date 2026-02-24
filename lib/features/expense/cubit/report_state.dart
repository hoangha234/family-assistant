part of 'report_cubit.dart';

/// Timeframe options for reports
enum ReportTimeframe {
  week,
  month,
  year;

  String get displayName {
    switch (this) {
      case ReportTimeframe.week:
        return 'Week';
      case ReportTimeframe.month:
        return 'Month';
      case ReportTimeframe.year:
        return 'Year';
    }
  }
}

/// Trend direction
enum TrendDirection {
  up,
  down,
  stable;
}

/// Category report data
class CategoryReport {
  final String category;
  final double amount;
  final double percentage;
  final TrendDirection trend;
  final double trendPercentage;

  const CategoryReport({
    required this.category,
    required this.amount,
    required this.percentage,
    this.trend = TrendDirection.stable,
    this.trendPercentage = 0.0,
  });
}

/// Status for report cubit
enum ReportCubitStatus {
  initial,
  loading,
  loaded,
  error,
}

class ReportState extends Equatable {
  final ReportTimeframe selectedTimeframe;
  final ReportCubitStatus status;
  final double totalSpent;
  final double previousTotalSpent;
  final List<CategoryReport> categoryReports;
  final TrendDirection overallTrend;
  final double overallTrendPercentage;
  final String? errorMessage;

  const ReportState({
    this.selectedTimeframe = ReportTimeframe.month,
    this.status = ReportCubitStatus.initial,
    this.totalSpent = 0.0,
    this.previousTotalSpent = 0.0,
    this.categoryReports = const [],
    this.overallTrend = TrendDirection.stable,
    this.overallTrendPercentage = 0.0,
    this.errorMessage,
  });

  bool get isLoading => status == ReportCubitStatus.loading;
  bool get isLoaded => status == ReportCubitStatus.loaded;
  bool get hasError => status == ReportCubitStatus.error;

  /// Get top 5 categories
  List<CategoryReport> get topCategories => categoryReports.take(5).toList();

  ReportState copyWith({
    ReportTimeframe? selectedTimeframe,
    ReportCubitStatus? status,
    double? totalSpent,
    double? previousTotalSpent,
    List<CategoryReport>? categoryReports,
    TrendDirection? overallTrend,
    double? overallTrendPercentage,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReportState(
      selectedTimeframe: selectedTimeframe ?? this.selectedTimeframe,
      status: status ?? this.status,
      totalSpent: totalSpent ?? this.totalSpent,
      previousTotalSpent: previousTotalSpent ?? this.previousTotalSpent,
      categoryReports: categoryReports ?? this.categoryReports,
      overallTrend: overallTrend ?? this.overallTrend,
      overallTrendPercentage: overallTrendPercentage ?? this.overallTrendPercentage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        selectedTimeframe,
        status,
        totalSpent,
        previousTotalSpent,
        categoryReports,
        overallTrend,
        overallTrendPercentage,
        errorMessage,
      ];
}
