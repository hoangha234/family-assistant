import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Model representing a virtual wallet
class WalletModel extends Equatable {
  final String id;
  final String name;
  final double balance;
  final bool isVirtual;
  final DateTime createdAt;

  const WalletModel({
    required this.id,
    required this.name,
    required this.balance,
    this.isVirtual = true,
    required this.createdAt,
  });

  /// Create a default Cash Wallet
  factory WalletModel.defaultCashWallet() {
    return WalletModel(
      id: '',
      name: 'Cash Wallet',
      balance: 0.0,
      isVirtual: true,
      createdAt: DateTime.now(),
    );
  }

  /// Create from Firestore document
  factory WalletModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Unnamed Wallet',
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
      isVirtual: data['isVirtual'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'balance': balance,
      'isVirtual': isVirtual,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  WalletModel copyWith({
    String? id,
    String? name,
    double? balance,
    bool? isVirtual,
    DateTime? createdAt,
  }) {
    return WalletModel(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      isVirtual: isVirtual ?? this.isVirtual,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, balance, isVirtual, createdAt];

  @override
  String toString() => 'WalletModel(id: $id, name: $name, balance: $balance)';
}

