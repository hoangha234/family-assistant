part of 'wallet_cubit.dart';

/// Enum representing wallet operation status
enum WalletStatus {
  initial,
  loading,
  loaded,
  adding,
  updating,
  deleting,
  error,
}

/// State class for WalletCubit
class WalletState extends Equatable {
  final List<WalletModel> wallets;
  final WalletModel? selectedWallet;
  final WalletStatus status;
  final String? errorMessage;

  const WalletState({
    this.wallets = const [],
    this.selectedWallet,
    this.status = WalletStatus.initial,
    this.errorMessage,
  });

  /// Check if wallets are loading
  bool get isLoading => status == WalletStatus.loading;

  /// Check if there's an error
  bool get hasError => status == WalletStatus.error;

  /// Get total balance across all wallets
  double get totalBalance => wallets.fold(0.0, (sum, w) => sum + w.balance);

  /// Get wallet count
  int get walletCount => wallets.length;

  WalletState copyWith({
    List<WalletModel>? wallets,
    WalletModel? selectedWallet,
    WalletStatus? status,
    String? errorMessage,
    bool clearError = false,
    bool clearSelectedWallet = false,
  }) {
    return WalletState(
      wallets: wallets ?? this.wallets,
      selectedWallet: clearSelectedWallet ? null : (selectedWallet ?? this.selectedWallet),
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [wallets, selectedWallet, status, errorMessage];
}

