import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/wallet_model.dart';
import '../repositories/wallet_repository.dart';

part 'wallet_state.dart';

/// Cubit for managing wallet operations
class WalletCubit extends Cubit<WalletState> {
  final WalletRepository _repository;
  StreamSubscription<List<WalletModel>>? _walletsSubscription;

  WalletCubit({WalletRepository? repository})
      : _repository = repository ?? WalletRepository(),
        super(const WalletState());

  /// Initialize and load wallets
  Future<void> loadWallets() async {
    emit(state.copyWith(status: WalletStatus.loading, clearError: true));

    try {
      // Create default wallet if needed
      await _repository.createDefaultWalletIfNeeded();

      // Subscribe to wallet updates
      _walletsSubscription?.cancel();
      _walletsSubscription = _repository.watchWallets().listen(
        (wallets) {
          emit(state.copyWith(
            wallets: wallets,
            status: WalletStatus.loaded,
            // Auto-select first wallet if none selected
            selectedWallet: state.selectedWallet ?? (wallets.isNotEmpty ? wallets.first : null),
          ));
        },
        onError: (error) {
          emit(state.copyWith(
            status: WalletStatus.error,
            errorMessage: error.toString(),
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: WalletStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Add a new wallet
  Future<void> addWallet({
    required String name,
    double initialBalance = 0.0,
    bool isVirtual = true,
  }) async {
    if (name.trim().isEmpty) {
      emit(state.copyWith(
        status: WalletStatus.error,
        errorMessage: 'Wallet name cannot be empty',
      ));
      return;
    }

    emit(state.copyWith(status: WalletStatus.adding, clearError: true));

    try {
      final wallet = WalletModel(
        id: '',
        name: name.trim(),
        balance: initialBalance,
        isVirtual: isVirtual,
        createdAt: DateTime.now(),
      );

      await _repository.addWallet(wallet);
      emit(state.copyWith(status: WalletStatus.loaded));
    } catch (e) {
      emit(state.copyWith(
        status: WalletStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Update wallet name
  Future<void> updateWalletName(String walletId, String newName) async {
    if (newName.trim().isEmpty) {
      emit(state.copyWith(
        status: WalletStatus.error,
        errorMessage: 'Wallet name cannot be empty',
      ));
      return;
    }

    emit(state.copyWith(status: WalletStatus.updating, clearError: true));

    try {
      await _repository.updateWalletName(walletId, newName.trim());
      emit(state.copyWith(status: WalletStatus.loaded));
    } catch (e) {
      emit(state.copyWith(
        status: WalletStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Adjust wallet balance manually
  Future<void> adjustBalance(String walletId, double newBalance) async {
    emit(state.copyWith(status: WalletStatus.updating, clearError: true));

    try {
      await _repository.adjustBalance(walletId, newBalance);
      emit(state.copyWith(status: WalletStatus.loaded));
    } catch (e) {
      emit(state.copyWith(
        status: WalletStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Deduct amount from wallet (for purchases)
  Future<void> deductFromWallet(String walletId, double amount) async {
    if (amount <= 0) {
      emit(state.copyWith(
        status: WalletStatus.error,
        errorMessage: 'Amount must be positive',
      ));
      return;
    }

    emit(state.copyWith(status: WalletStatus.updating, clearError: true));

    try {
      await _repository.deductBalance(walletId, amount);
      emit(state.copyWith(status: WalletStatus.loaded));
    } catch (e) {
      emit(state.copyWith(
        status: WalletStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Add amount to wallet
  Future<void> addToWallet(String walletId, double amount) async {
    if (amount <= 0) {
      emit(state.copyWith(
        status: WalletStatus.error,
        errorMessage: 'Amount must be positive',
      ));
      return;
    }

    emit(state.copyWith(status: WalletStatus.updating, clearError: true));

    try {
      await _repository.addBalance(walletId, amount);
      emit(state.copyWith(status: WalletStatus.loaded));
    } catch (e) {
      emit(state.copyWith(
        status: WalletStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Delete wallet
  Future<void> deleteWallet(String walletId) async {
    emit(state.copyWith(status: WalletStatus.deleting, clearError: true));

    try {
      await _repository.deleteWallet(walletId);

      // Clear selected wallet if it was deleted
      if (state.selectedWallet?.id == walletId) {
        emit(state.copyWith(
          status: WalletStatus.loaded,
          clearSelectedWallet: true,
        ));
      } else {
        emit(state.copyWith(status: WalletStatus.loaded));
      }
    } catch (e) {
      emit(state.copyWith(
        status: WalletStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Select a wallet
  void selectWallet(WalletModel wallet) {
    emit(state.copyWith(selectedWallet: wallet));
  }

  /// Select wallet by ID
  void selectWalletById(String walletId) {
    final wallet = state.wallets.firstWhere(
      (w) => w.id == walletId,
      orElse: () => state.wallets.first,
    );
    emit(state.copyWith(selectedWallet: wallet));
  }

  /// Clear any error
  void clearError() {
    emit(state.copyWith(clearError: true, status: WalletStatus.loaded));
  }

  @override
  Future<void> close() {
    _walletsSubscription?.cancel();
    return super.close();
  }
}

