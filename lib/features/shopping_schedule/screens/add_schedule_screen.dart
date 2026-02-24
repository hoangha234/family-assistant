import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../cubit/add_schedule_cubit.dart';
import '../services/shopping_service.dart';
import '../../wallet/wallet.dart';

class AddScheduleScreen extends StatelessWidget {
  const AddScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AddScheduleCubit()),
        BlocProvider(create: (context) => WalletCubit()..loadWallets()),
      ],
      child: const AddScheduleView(),
    );
  }
}

class AddScheduleView extends StatefulWidget {
  const AddScheduleView({super.key});

  @override
  State<AddScheduleView> createState() => _AddScheduleViewState();
}

class _AddScheduleViewState extends State<AddScheduleView> {
  static const Color primaryColor = Color(0xFF056DB8);
  static const Color bgDark = Color(0xFF0F1B23);
  static const Color textDark = Color(0xFF111518);
  static const Color borderLight = Color(0xFFDBE1E6);
  static const Color borderDark = Color(0xFF374151);


  final List<Map<String, dynamic>> _categories = const [
    {'name': 'Groceries', 'icon': Icons.shopping_cart},
    {'name': 'Health', 'icon': Icons.medical_services},
    {'name': 'Home', 'icon': Icons.home},
    {'name': 'Tech', 'icon': Icons.devices},
    {'name': 'Other', 'icon': Icons.more_horiz},
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      context.read<AddScheduleCubit>().updateDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? bgDark : Colors.white;
    final textColor = isDarkMode ? Colors.white : textDark;
    final inputFillColor = isDarkMode ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDarkMode ? borderDark : borderLight;

    return BlocBuilder<AddScheduleCubit, AddScheduleState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, textColor, isDarkMode),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item Name
                        _buildLabel("Item Name", textColor),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildTextField(
                            onChanged: (val) => context.read<AddScheduleCubit>().updateName(val),
                            hint: "e.g. Organic Almond Milk",
                            isDarkMode: isDarkMode,
                            borderColor: borderColor,
                            fillColor: inputFillColor,
                            textColor: textColor,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Estimated Cost
                        _buildLabel("Estimated Cost", textColor),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildTextField(
                            onChanged: (val) => context.read<AddScheduleCubit>().updateCost(val),
                            hint: "0.00",
                            isDarkMode: isDarkMode,
                            borderColor: borderColor,
                            fillColor: inputFillColor,
                            textColor: textColor,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            prefixIcon: Icon(Icons.attach_money, color: isDarkMode ? Colors.grey[400] : const Color(0xFF5F798C)),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Category
                        _buildLabel("Category", textColor),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: _categories.map((cat) {
                              final isSelected = state.selectedCategory == cat['name'];
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: InkWell(
                                  onTap: () => context.read<AddScheduleCubit>().updateCategory(cat['name']),
                                  borderRadius: BorderRadius.circular(50),
                                  child: Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? primaryColor
                                          : (isDarkMode ? Colors.grey[800] : const Color(0xFFF0F3F5)),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          cat['icon'],
                                          size: 18,
                                          color: isSelected
                                              ? Colors.white
                                              : (isDarkMode ? Colors.grey[300] : textDark),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          cat['name'],
                                          style: GoogleFonts.manrope(
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                            color: isSelected
                                                ? Colors.white
                                                : (isDarkMode ? Colors.grey[300] : textDark),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Due Date
                        _buildLabel("Due Date", textColor),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GestureDetector(
                            onTap: () => _selectDate(context),
                            child: AbsorbPointer(
                              child: _buildTextField(
                                hint: state.selectedDate == null
                                    ? "mm/dd/yyyy"
                                    : DateFormat('MM/dd/yyyy').format(state.selectedDate!),
                                isDarkMode: isDarkMode,
                                borderColor: borderColor,
                                fillColor: inputFillColor,
                                textColor: textColor,
                                suffixIcon: Icon(Icons.calendar_today, color: isDarkMode ? Colors.grey[400] : const Color(0xFF5F798C)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Payment Type Selector
                        _buildLabel("Payment Type", textColor),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildPaymentTypeSelector(context, isDarkMode, textColor, state),
                        ),
                        const SizedBox(height: 24),

                        // Conditional: Wallet & Repeat Cycle (only for Automatic)
                        if (state.paymentMode == PaymentMode.automatic) ...[
                          // Wallet Selector
                          _buildLabel("Payment Wallet", textColor),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildWalletSelector(context, isDarkMode, borderColor, inputFillColor, textColor, state),
                          ),
                          const SizedBox(height: 24),

                          // Repeat Cycle
                          _buildLabel("Repeat Cycle", textColor),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildRepeatCycleSelector(context, isDarkMode, textColor, state),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Notes
                        _buildLabel("Notes", textColor),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildTextField(
                            onChanged: (val) => context.read<AddScheduleCubit>().updateNotes(val),
                            hint: "Add some details about this purchase...",
                            isDarkMode: isDarkMode,
                            borderColor: borderColor,
                            fillColor: inputFillColor,
                            textColor: textColor,
                            maxLines: 4,
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
                _buildSaveButton(context, state, backgroundColor, isDarkMode),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentTypeSelector(BuildContext context, bool isDarkMode, Color textColor, AddScheduleState state) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : const Color(0xFFF0F3F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildPaymentTypeOption(
            context,
            'Manual Purchase',
            Icons.touch_app,
            PaymentMode.manual,
            isDarkMode,
            textColor,
            state,
          ),
          _buildPaymentTypeOption(
            context,
            'Automatic',
            Icons.autorenew,
            PaymentMode.automatic,
            isDarkMode,
            textColor,
            state,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeOption(
    BuildContext context,
    String label,
    IconData icon,
    PaymentMode mode,
    bool isDarkMode,
    Color textColor,
    AddScheduleState state,
  ) {
    final isSelected = state.paymentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          context.read<AddScheduleCubit>().updatePaymentMode(mode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : (isDarkMode ? Colors.grey[400] : textColor),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : (isDarkMode ? Colors.grey[400] : textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletSelector(BuildContext context, bool isDarkMode, Color borderColor, Color fillColor, Color textColor, AddScheduleState scheduleState) {
    return BlocBuilder<WalletCubit, WalletState>(
      builder: (context, walletState) {
        final wallets = walletState.wallets;

        if (walletState.isLoading) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (wallets.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'No wallets available. Create one first.',
                  style: GoogleFonts.manrope(color: textColor.withValues(alpha: 0.7)),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: scheduleState.selectedWalletId ?? wallets.first.id,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: textColor),
              dropdownColor: fillColor,
              items: wallets.map((wallet) {
                final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
                return DropdownMenuItem<String>(
                  value: wallet.id,
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet, size: 20, color: primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          wallet.name,
                          style: GoogleFonts.manrope(color: textColor),
                        ),
                      ),
                      Text(
                        currencyFormat.format(wallet.balance),
                        style: GoogleFonts.manrope(
                          color: wallet.balance < 0 ? Colors.red : primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                context.read<AddScheduleCubit>().updateWallet(value);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildRepeatCycleSelector(BuildContext context, bool isDarkMode, Color textColor, AddScheduleState state) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : const Color(0xFFF0F3F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildRepeatOption(context, 'One-time', Icons.looks_one, RepeatCycle.none, isDarkMode, textColor, state),
          _buildRepeatOption(context, 'Monthly', Icons.repeat, RepeatCycle.monthly, isDarkMode, textColor, state),
        ],
      ),
    );
  }

  Widget _buildRepeatOption(
    BuildContext context,
    String label,
    IconData icon,
    RepeatCycle cycle,
    bool isDarkMode,
    Color textColor,
    AddScheduleState state,
  ) {
    final isSelected = state.repeatCycle == cycle;
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<AddScheduleCubit>().updateRepeatCycle(cycle),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : (isDarkMode ? Colors.grey[400] : textColor),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : (isDarkMode ? Colors.grey[400] : textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, AddScheduleState state, Color backgroundColor, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: isDarkMode ? Colors.grey[800]! : Colors.grey[100]!)),
      ),
      child: Column(
        children: [
          // Error message
          if (state.hasError && state.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 18, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Info banner for automatic payments
          if (state.paymentMode == PaymentMode.automatic) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payment will be automatically deducted from the selected wallet on the due date.',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: state.isSaving
                  ? null
                  : () async {
                      final success = await context.read<AddScheduleCubit>().saveItem();
                      if (success && context.mounted) {
                        Navigator.pop(context, true); // Return true to indicate success
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 4,
                shadowColor: primaryColor.withValues(alpha: 0.4),
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
                        const Icon(Icons.save, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          "Save Schedule",
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

  Widget _buildHeader(BuildContext context, Color textColor, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDarkMode ? Colors.grey[800]! : Colors.grey[100]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_ios, color: textColor, size: 24),
          ),
          Text(
            "Add Schedule",
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTextField({
    void Function(String)? onChanged,
    required String hint,
    required bool isDarkMode,
    required Color borderColor,
    required Color fillColor,
    required Color textColor,
    TextInputType? keyboardType,
    Widget? prefixIcon,
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.manrope(
          fontSize: 16,
          color: textColor,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.manrope(
            color: isDarkMode ? Colors.grey[500] : const Color(0xFF5F798C),
          ),
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primaryColor, width: 1.5),
          ),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
