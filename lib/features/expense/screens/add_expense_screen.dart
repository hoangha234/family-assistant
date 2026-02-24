import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../cubit/add_expense_cubit.dart';

class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddExpenseCubit(),
      child: const AddExpenseView(),
    );
  }
}

class AddExpenseView extends StatelessWidget {
  const AddExpenseView({super.key});

  final Color primaryColor = const Color(0xFF0694F9);
  final Color bgLight = const Color(0xFFF5F7F8);
  final Color bgDark = const Color(0xFF0F1B23);
  final Color textDark = const Color(0xFF111518);

  final List<Map<String, dynamic>> _categories = const [
    {'name': 'Food', 'icon': Icons.restaurant},
    {'name': 'Transport', 'icon': Icons.directions_car},
    {'name': 'Rent', 'icon': Icons.home},
    {'name': 'Shopping', 'icon': Icons.shopping_bag},
    {'name': 'Health', 'icon': Icons.health_and_safety},
  ];

  String _getFormattedAmount(String amount) {
    if (amount.endsWith('.')) return "\$$amount";
    try {
      final doubleValue = double.parse(amount);
      final formatter = NumberFormat("#,##0.##", "en_US");
      return "\$${formatter.format(doubleValue)}";
    } catch (e) {
      return "\$$amount";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? bgDark : Colors.white;
    final textColor = isDarkMode ? Colors.white : textDark;

    return BlocListener<AddExpenseCubit, AddExpenseState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.isSuccess) {
          Navigator.pop(context, true);
        } else if (state.hasError && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<AddExpenseCubit, AddExpenseState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, textColor),
                _buildSegmentedControl(context, state, isDarkMode),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "ENTER AMOUNT",
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _getFormattedAmount(state.amount),
                          style: GoogleFonts.manrope(
                            fontSize: 56,
                            fontWeight: FontWeight.w800,
                            color: primaryColor,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCategoryList(context, state, isDarkMode, textColor),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900]!.withOpacity(0.5) : bgLight.withOpacity(0.5),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(top: BorderSide(color: isDarkMode ? Colors.grey[800]! : Colors.grey[100]!)),
                  ),
                  child: Column(
                    children: [
                      _buildKeypad(context, isDarkMode, textColor),
                      const SizedBox(height: 16),
                      _buildConfirmButton(context, state),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.close, color: textColor, size: 24),
            ),
          ),
          Text(
            "Quick Add",
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.help_outline, color: textColor, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl(BuildContext context, AddExpenseState state, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : bgLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildSegmentTab(context, "Expense", state.transactionType == "Expense", isDarkMode),
          _buildSegmentTab(context, "Income", state.transactionType == "Income", isDarkMode),
        ],
      ),
    );
  }

  Widget _buildSegmentTab(BuildContext context, String text, bool isActive, bool isDarkMode) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<AddExpenseCubit>().setTransactionType(text),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? (isDarkMode ? Colors.grey[700] : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))]
                : [],
          ),
          child: Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isActive ? primaryColor : (isDarkMode ? Colors.grey[400] : Colors.grey[500]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, AddExpenseState state, bool isDarkMode, Color textColor) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = state.selectedCategory == cat['name'];
          return GestureDetector(
            onTap: () => context.read<AddExpenseCubit>().setCategory(cat['name']),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected 
                    ? primaryColor 
                    : (isDarkMode ? Colors.grey[800] : bgLight),
                borderRadius: BorderRadius.circular(50),
                boxShadow: isSelected
                    ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Row(
                children: [
                  Icon(
                    cat['icon'],
                    size: 20,
                    color: isSelected ? Colors.white : (isDarkMode ? Colors.grey[300] : Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cat['name'],
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : (isDarkMode ? Colors.grey[300] : Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildKeypad(BuildContext context, bool isDarkMode, Color textColor) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      childAspectRatio: 1.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((num) => _buildKeypadButton(context, num, isDarkMode, textColor)),
        _buildKeypadButton(context, '.', isDarkMode, textColor, isTransparent: true),
        _buildKeypadButton(context, '0', isDarkMode, textColor),
        _buildBackspaceButton(context),
      ],
    );
  }

  Widget _buildKeypadButton(BuildContext context, String label, bool isDarkMode, Color textColor, {bool isTransparent = false}) {
    return Material(
      color: isTransparent 
          ? Colors.transparent 
          : (isDarkMode ? Colors.grey[800] : Colors.white),
      borderRadius: BorderRadius.circular(16),
      elevation: isTransparent ? 0 : 1,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: () => context.read<AddExpenseCubit>().onKeyTap(label),
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isTransparent ? Colors.grey[500] : textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.read<AddExpenseCubit>().onBackspace(),
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Icon(Icons.backspace_outlined, color: Colors.grey[500], size: 24),
        ),
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context, AddExpenseState state) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: state.isSaving
            ? null
            : () {
                context.read<AddExpenseCubit>().confirmTransaction();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: state.isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 24),
            const SizedBox(width: 8),
            Text(
              "Confirm Transaction",
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
