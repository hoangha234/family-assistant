import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../cubit/wallet_cubit.dart';
import '../models/wallet_model.dart';

/// Widget for selecting a wallet
/// Can be used in Add Schedule, Manual Purchase, etc.
class WalletSelector extends StatelessWidget {
  final WalletModel? selectedWallet;
  final ValueChanged<WalletModel> onWalletSelected;
  final bool showBalance;
  final String? label;

  const WalletSelector({
    super.key,
    this.selectedWallet,
    required this.onWalletSelected,
    this.showBalance = true,
    this.label,
  });

  static const Color primaryColor = Color(0xFF056DB8);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF111518);
    final borderColor = isDarkMode ? const Color(0xFF374151) : const Color(0xFFDBE1E6);
    final fillColor = isDarkMode ? const Color(0xFF111827) : Colors.white;

    return BlocBuilder<WalletCubit, WalletState>(
      builder: (context, state) {
        if (state.isLoading) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(12),
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

        final wallets = state.wallets;
        if (wallets.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              'No wallets available',
              style: GoogleFonts.manrope(color: textColor.withValues(alpha: 0.5)),
            ),
          );
        }

        final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
        final currentWallet = selectedWallet ?? wallets.first;

        return GestureDetector(
          onTap: () => _showWalletPicker(context, wallets, currentWallet),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (label != null)
                        Text(
                          label!,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: textColor.withValues(alpha: 0.6),
                          ),
                        ),
                      Text(
                        currentWallet.name,
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      if (showBalance)
                        Text(
                          currencyFormat.format(currentWallet.balance),
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: currentWallet.balance < 0
                                ? Colors.red
                                : primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: textColor.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWalletPicker(
    BuildContext context,
    List<WalletModel> wallets,
    WalletModel currentWallet,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF111518);
    final cardColor = isDarkMode ? const Color(0xFF1A2530) : Colors.white;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Select Wallet',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: wallets.length,
                  itemBuilder: (context, index) {
                    final wallet = wallets[index];
                    final isSelected = wallet.id == currentWallet.id;

                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        wallet.name,
                        style: GoogleFonts.manrope(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      subtitle: Text(
                        currencyFormat.format(wallet.balance),
                        style: GoogleFonts.manrope(
                          color: wallet.balance < 0 ? Colors.red : primaryColor,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: primaryColor)
                          : null,
                      onTap: () {
                        onWalletSelected(wallet);
                        Navigator.pop(bottomSheetContext);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

/// A simple dropdown version of wallet selector
class WalletDropdown extends StatelessWidget {
  final String? selectedWalletId;
  final ValueChanged<String?> onChanged;
  final String? label;

  const WalletDropdown({
    super.key,
    this.selectedWalletId,
    required this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF111518);
    final borderColor = isDarkMode ? const Color(0xFF374151) : const Color(0xFFDBE1E6);
    final fillColor = isDarkMode ? const Color(0xFF111827) : Colors.white;

    return BlocBuilder<WalletCubit, WalletState>(
      builder: (context, state) {
        final wallets = state.wallets;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  label!,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedWalletId ?? (wallets.isNotEmpty ? wallets.first.id : null),
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: textColor),
                  dropdownColor: fillColor,
                  items: wallets.map((wallet) {
                    return DropdownMenuItem<String>(
                      value: wallet.id,
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: 20,
                            color: WalletSelector.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            wallet.name,
                            style: GoogleFonts.manrope(color: textColor),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

