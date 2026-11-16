/// [WalletLedgerModel] represents an itemized entry in the user's credit passbook.
/// Tracks top-ups, generation debits, 4K download unlocks, royalties, and refunds.
class WalletLedgerModel {
  final String id;
  final double amount;
  final double balanceAfter;
  final String eventType;
  final String description;
  final String? referenceId;
  final DateTime createdAt;

  const WalletLedgerModel({
    required this.id,
    required this.amount,
    required this.balanceAfter,
    required this.eventType,
    required this.description,
    this.referenceId,
    required this.createdAt,
  });

  /// Whether this is a credit addition (positive amount)
  bool get isCredit => amount > 0;

  factory WalletLedgerModel.fromJson(Map<String, dynamic> json) {
    return WalletLedgerModel(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0.0,
      eventType: json['event_type']?.toString() ?? 'other',
      description: json['description']?.toString() ?? 'Credit activity',
      referenceId: json['reference_id']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'balance_after': balanceAfter,
      'event_type': eventType,
      'description': description,
      'reference_id': referenceId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

