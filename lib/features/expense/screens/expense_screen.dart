import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../cubit/expense_cubit.dart';
import '../category/cubit/category_budget_cubit.dart';
import '../category/cubit/category_budget_state.dart';
import '../category/models/category_budget_model.dart';
import 'add_expense_screen.dart';
import 'report_screen.dart';

class ExpenseScreen extends StatelessWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ExpenseCubit()..initialize(),
        ),
        BlocProvider(
          create: (context) => CategoryBudgetCubit()..initialize(),
        ),
      ],
      child: const ExpenseView(),
    );
  }
}

class ExpenseView extends StatefulWidget {
  const ExpenseView({super.key});

  @override
  State<ExpenseView> createState() => _ExpenseViewState();
}

class _ExpenseViewState extends State<ExpenseView> {
  final Color primaryColor = const Color(0xFF0694F9);
  final Color bgLight = const Color(0xFFF5F7F8);
  final Color bgDark = const Color(0xFF0F1B23);
  final Color successColor = const Color(0xFF22C55E);
  final Color warningColor = const Color(0xFFFACC15);
  final Color errorColor = const Color(0xFFEF4444);
  final Color dangerColor = const Color(0xFFDC2626);
  final Color textDark = const Color(0xFF111518);
  final Color textGrey = const Color(0xFF5F798C);

  @override
  void initState() {
    super.initState();
    // Link ExpenseCubit to CategoryBudgetCubit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final expenseCubit = context.read<ExpenseCubit>();
      final categoryBudgetCubit = context.read<CategoryBudgetCubit>();

      // When expenses change, update category budgets
      expenseCubit.setOnExpensesChangedCallback((totalBalance, categoryTotals) {
        categoryBudgetCubit.updateTotalBalance(totalBalance, categoryTotals);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode ? bgDark : bgLight;
    final Color textColor = isDarkMode ? Colors.white : textDark;

    return BlocConsumer<CategoryBudgetCubit, CategoryBudgetState>(
      listener: (context, categoryState) {
        // Show validation error snackbar
        if (categoryState is CategoryBudgetValidationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(categoryState.errorMessage),
              backgroundColor: errorColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        // Show success message
        if (categoryState is CategoryBudgetUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(categoryState.message),
              backgroundColor: successColor,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, categoryState) {
        return BlocBuilder<ExpenseCubit, ExpenseState>(
          builder: (context, state) {
            return Scaffold(
              backgroundColor: backgroundColor,
              appBar: AppBar(
                backgroundColor: isDarkMode ? bgDark : Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Expense Overview',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.notifications_outlined, color: textColor),
                    onPressed: () {},
                  ),
                ],
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    _buildMonthSelector(context, state, isDarkMode),
                    Expanded(
                      child: state.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          children: [
                            _buildBalanceCard(state),
                            _buildAIInsight(),
                            _buildJarBudgetUtilization(context, categoryState, textColor, isDarkMode),
                            _buildQuickActions(context, textColor, isDarkMode),
                            _buildRecentTransactions(state, textColor, isDarkMode),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMonthSelector(BuildContext context, ExpenseState state, bool isDarkMode) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    // Auto-scroll to selected month logic could be added using a ScrollController 
    // mapped to state.selectedMonthIndex. For now, it will just use a SingleChildScrollView.

    return Container(
      color: isDarkMode ? bgDark : Colors.white,
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(months.length, (index) {
            final isSelected = index == state.selectedMonthIndex;
            return GestureDetector(
              onTap: () => context.read<ExpenseCubit>().setMonth(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? primaryColor : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  months[index],
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? primaryColor : textGrey,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(ExpenseState state) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final balanceStr = formatter.format(state.totalBalance);
    final incomeStr = '+${formatter.format(state.totalIncome)}';
    final expenseStr = '-${formatter.format(state.totalExpense)}';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Balance',
                            style: GoogleFonts.manrope(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            balanceStr,
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Live Data',
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMiniStatCard(
                          label: 'Income',
                          value: incomeStr,
                          isIncome: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMiniStatCard(
                          label: 'Expenses',
                          value: expenseStr,
                          isIncome: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatCard({required String label, required String value, required bool isIncome}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.manrope(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsight() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: primaryColor.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.psychology, color: primaryColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: primaryColor,
                    height: 1.4,
                  ),
                  children: const [
                    TextSpan(text: 'AI Insight: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: 'You\'ve spent 15% less on dining out compared to last month. Great job!'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetUtilization(ExpenseState state, Color textColor, bool isDarkMode) {
    // This method is deprecated, use _buildJarBudgetUtilization instead
    return const SizedBox.shrink();
  }

  /// NEW: Jar Budget System UI
  Widget _buildJarBudgetUtilization(
    BuildContext context,
    CategoryBudgetState categoryState,
    Color textColor,
    bool isDarkMode,
  ) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget Jars',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              if (categoryState is CategoryBudgetLoaded)
                Text(
                  'Allocated: ${formatter.format(categoryState.totalAllocatedBudget)}',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textGrey,
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildCategoryBudgetList(context, categoryState, textColor, isDarkMode),
        ),
      ],
    );
  }

  Widget _buildCategoryBudgetList(
    BuildContext context,
    CategoryBudgetState categoryState,
    Color textColor,
    bool isDarkMode,
  ) {
    if (categoryState is CategoryBudgetLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (categoryState is CategoryBudgetError) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1A2737) : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            categoryState.message,
            style: GoogleFonts.manrope(color: errorColor),
          ),
        ),
      );
    }

    List<CategoryBudget> categories = [];
    if (categoryState is CategoryBudgetLoaded) {
      categories = categoryState.categories;
    } else if (categoryState is CategoryBudgetUpdating) {
      categories = categoryState.categories;
    } else if (categoryState is CategoryBudgetUpdateSuccess) {
      categories = categoryState.categories;
    } else if (categoryState is CategoryBudgetValidationError) {
      categories = categoryState.categories;
    }

    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1A2737) : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'No budget categories yet',
            style: GoogleFonts.manrope(color: textGrey),
          ),
        ),
      );
    }

    return Column(
      children: categories.asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value;
        final isUpdating = categoryState is CategoryBudgetUpdating &&
            categoryState.updatingCategoryId == category.id;

        return Padding(
          padding: EdgeInsets.only(bottom: index < categories.length - 1 ? 8 : 0),
          child: _buildJarBudgetCard(
            context: context,
            category: category,
            textColor: textColor,
            isDarkMode: isDarkMode,
            isUpdating: isUpdating,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildJarBudgetCard({
    required BuildContext context,
    required CategoryBudget category,
    required Color textColor,
    required bool isDarkMode,
    bool isUpdating = false,
  }) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final icon = _getCategoryIcon(category.name);
    final progressColor = _getProgressBarColor(category.status);
    final percent = category.spendingPercentage.clamp(0.0, 1.5);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A2737) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: category.isOverspent
              ? dangerColor.withAlpha(128)
              : (isDarkMode ? Colors.white10 : Colors.grey[100]!),
          width: category.isOverspent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: progressColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: progressColor),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Remaining: ${formatter.format(category.remainingAmount.clamp(0, double.infinity))}',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: category.isOverspent ? dangerColor : textGrey,
                          fontWeight: category.isOverspent ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Edit budget button
              IconButton(
                icon: isUpdating
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryColor,
                        ),
                      )
                    : Icon(Icons.edit_outlined, size: 18, color: textGrey),
                onPressed: isUpdating
                    ? null
                    : () => _showEditBudgetDialog(context, category),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Spent / Budget text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${formatter.format(category.totalSpent)} / ${formatter.format(category.monthlyBudget)}',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: progressColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${category.spendingPercentageInt}%',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFDBE1E6),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
          // Overspent warning
          if (category.isOverspent) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: dangerColor),
                const SizedBox(width: 4),
                Text(
                  'Overspent by ${formatter.format(category.totalSpent - category.monthlyBudget)}',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: dangerColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Get progress bar color based on budget status
  Color _getProgressBarColor(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.safe:
        return successColor;
      case BudgetStatus.warning:
        return warningColor;
      case BudgetStatus.danger:
        return errorColor;
      case BudgetStatus.overspent:
        return dangerColor;
    }
  }

  /// Show edit budget dialog
  void _showEditBudgetDialog(BuildContext context, CategoryBudget category) {
    final controller = TextEditingController(
      text: category.monthlyBudget.toStringAsFixed(0),
    );
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Capture the cubit BEFORE showing dialog
    final categoryBudgetCubit = context.read<CategoryBudgetCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1A2737) : Colors.white,
          title: Text(
            'Edit ${category.name} Budget',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : textDark,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: GoogleFonts.manrope(
                  color: isDarkMode ? Colors.white : textDark,
                ),
                decoration: InputDecoration(
                  labelText: 'Monthly Budget',
                  prefixText: '\$ ',
                  labelStyle: GoogleFonts.manrope(color: textGrey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Current spent: \$${category.totalSpent.toStringAsFixed(0)}',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: textGrey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.manrope(color: textGrey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newBudget = double.tryParse(controller.text) ?? 0;
                print('[Dialog] Saving budget: categoryId=${category.id}, newBudget=$newBudget');
                print('[Dialog] Category name: ${category.name}');

                // Close dialog first
                Navigator.pop(dialogContext);

                // Then update the budget
                try {
                  await categoryBudgetCubit.updateCategoryBudget(
                    category.id,
                    newBudget,
                  );
                  print('[Dialog] Update completed');
                } catch (e) {
                  print('[Dialog] Update error: $e');
                }
              },
              child: Text(
                'Save',
                style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'bills':
        return Icons.receipt;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'other':
        return Icons.more_horiz;
      case 'rent':
      case 'housing':
        return Icons.home;
      case 'groceries':
        return Icons.shopping_cart;
      default:
        return Icons.category;
    }
  }

  Widget _buildProgressBarItem({
    required IconData icon,
    required String title,
    required String spent,
    required String total,
    required double percent,
    required Color color,
    required String statusText,
    required Color statusColor,
    required Color textColor,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A2737) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: textGrey),
                  const SizedBox(width: 8),
                  Text(title, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              Text('$spent / $total', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: textColor)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: const Color(0xFFDBE1E6),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(statusText, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: statusColor)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Color textColor, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final categoryBudgetCubit = context.read<CategoryBudgetCubit>();
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddExpenseScreen(
                      categoryBudgetCubit: categoryBudgetCubit,
                    ),
                  ),
                );

                // Force recalculate when returning from AddExpenseScreen
                if (result == true && context.mounted) {
                  print('[ExpenseScreen] Returned from AddExpense, recalculating...');
                  categoryBudgetCubit.recalculateAllCategories();
                }
              },
              child: _buildActionButton(
                icon: Icons.add_circle,
                label: 'Add Expense',
                bgColor: primaryColor,
                textColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportScreen()),
                );
              },
              child: _buildActionButton(
                icon: Icons.bar_chart,
                label: 'View Reports',
                bgColor: isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
                textColor: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color bgColor, required Color textColor}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(ExpenseState state, Color textColor, bool isDarkMode) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormatter = DateFormat('MMMM dd, yyyy');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Icon(Icons.filter_list, color: textGrey),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: state.recentTransactions.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1A2737) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'No transactions yet',
                      style: GoogleFonts.manrope(color: textGrey),
                    ),
                  ),
                )
              : Column(
                  children: state.recentTransactions.map((expense) {
                    final isIncome = expense.isIncome;
                    final amountStr = isIncome
                        ? '+${formatter.format(expense.amount)}'
                        : '-${formatter.format(expense.amount)}';
                    final amountColor = isIncome ? successColor : errorColor;
                    final icon = _getCategoryIcon(expense.category);
                    final iconBg = isIncome
                        ? successColor.withOpacity(0.1)
                        : errorColor.withOpacity(0.1);
                    final iconColor = isIncome ? successColor : errorColor;

                    return _buildTransactionItem(
                      icon: icon,
                      iconBg: iconBg,
                      iconColor: iconColor,
                      title: expense.category,
                      date: dateFormatter.format(expense.createdAt),
                      amount: amountStr,
                      amountColor: amountColor,
                      textColor: textColor,
                      isDarkMode: isDarkMode,
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String date,
    required String amount,
    required Color amountColor,
    required Color textColor,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A2737) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.grey[100]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                  Text(date, style: GoogleFonts.manrope(fontSize: 12, color: textGrey)),
                ],
              ),
            ],
          ),
          Text(amount, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: amountColor)),
        ],
      ),
    );
  }
}
