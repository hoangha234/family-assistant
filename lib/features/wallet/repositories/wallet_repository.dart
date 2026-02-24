import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wallet_model.dart';

/// Repository for managing wallet data in Firestore
class WalletRepository {
  FirebaseFirestore? _firestoreInstance;
  final String _collectionPath = 'wallets';

  WalletRepository({FirebaseFirestore? firestore}) : _firestoreInstance = firestore;

  /// Lazy getter for Firestore instance
  FirebaseFirestore get _firestore {
    _firestoreInstance ??= FirebaseFirestore.instance;
    return _firestoreInstance!;
  }

  /// Get reference to wallets collection
  CollectionReference<Map<String, dynamic>> get _walletsRef =>
      _firestore.collection(_collectionPath);

  /// Load all wallets from Firestore
  Future<List<WalletModel>> getWallets() async {
    try {
      final snapshot = await _walletsRef
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => WalletModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw WalletRepositoryException('Failed to load wallets: $e');
    }
  }

  /// Stream of wallets for real-time updates
  Stream<List<WalletModel>> watchWallets() {
    return _walletsRef
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WalletModel.fromFirestore(doc))
            .toList());
  }

  /// Add a new wallet
  Future<WalletModel> addWallet(WalletModel wallet) async {
    try {
      final docRef = await _walletsRef.add(wallet.toFirestore());
      return wallet.copyWith(id: docRef.id);
    } catch (e) {
      throw WalletRepositoryException('Failed to add wallet: $e');
    }
  }

  /// Update wallet name
  Future<void> updateWalletName(String walletId, String newName) async {
    try {
      await _walletsRef.doc(walletId).update({'name': newName});
    } catch (e) {
      throw WalletRepositoryException('Failed to update wallet name: $e');
    }
  }

  /// Adjust wallet balance
  Future<void> adjustBalance(String walletId, double newBalance) async {
    try {
      await _walletsRef.doc(walletId).update({'balance': newBalance});
    } catch (e) {
      throw WalletRepositoryException('Failed to adjust balance: $e');
    }
  }

  /// Deduct amount from wallet balance
  Future<void> deductBalance(String walletId, double amount) async {
    try {
      final doc = await _walletsRef.doc(walletId).get();
      if (!doc.exists) {
        throw WalletRepositoryException('Wallet not found');
      }

      final currentBalance = (doc.data()?['balance'] as num?)?.toDouble() ?? 0.0;
      final newBalance = currentBalance - amount;

      await _walletsRef.doc(walletId).update({'balance': newBalance});
    } catch (e) {
      if (e is WalletRepositoryException) rethrow;
      throw WalletRepositoryException('Failed to deduct balance: $e');
    }
  }

  /// Add amount to wallet balance
  Future<void> addBalance(String walletId, double amount) async {
    try {
      final doc = await _walletsRef.doc(walletId).get();
      if (!doc.exists) {
        throw WalletRepositoryException('Wallet not found');
      }

      final currentBalance = (doc.data()?['balance'] as num?)?.toDouble() ?? 0.0;
      final newBalance = currentBalance + amount;

      await _walletsRef.doc(walletId).update({'balance': newBalance});
    } catch (e) {
      if (e is WalletRepositoryException) rethrow;
      throw WalletRepositoryException('Failed to add balance: $e');
    }
  }

  /// Delete wallet (check for linked schedules first)
  Future<void> deleteWallet(String walletId) async {
    try {
      // Check if wallet has linked schedules
      final hasLinkedSchedules = await _hasLinkedSchedules(walletId);
      if (hasLinkedSchedules) {
        throw WalletRepositoryException(
          'Cannot delete wallet: It has linked shopping schedules',
        );
      }

      await _walletsRef.doc(walletId).delete();
    } catch (e) {
      if (e is WalletRepositoryException) rethrow;
      throw WalletRepositoryException('Failed to delete wallet: $e');
    }
  }

  /// Check if wallet has linked shopping schedules
  Future<bool> _hasLinkedSchedules(String walletId) async {
    try {
      final snapshot = await _firestore
          .collection('shopping_schedules')
          .where('walletId', isEqualTo: walletId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      // If collection doesn't exist or error, assume no linked schedules
      return false;
    }
  }

  /// Get a single wallet by ID
  Future<WalletModel?> getWalletById(String walletId) async {
    try {
      final doc = await _walletsRef.doc(walletId).get();
      if (!doc.exists) return null;
      return WalletModel.fromFirestore(doc);
    } catch (e) {
      throw WalletRepositoryException('Failed to get wallet: $e');
    }
  }

  /// Create default wallet if none exists
  Future<WalletModel> createDefaultWalletIfNeeded() async {
    try {
      final wallets = await getWallets();
      if (wallets.isEmpty) {
        final defaultWallet = WalletModel.defaultCashWallet();
        return await addWallet(defaultWallet);
      }
      return wallets.first;
    } catch (e) {
      throw WalletRepositoryException('Failed to create default wallet: $e');
    }
  }
}

/// Custom exception for wallet repository errors
class WalletRepositoryException implements Exception {
  final String message;

  WalletRepositoryException(this.message);

  @override
  String toString() => 'WalletRepositoryException: $message';
}

