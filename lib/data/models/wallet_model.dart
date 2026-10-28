class WalletModel {
  final double purchasedBalance;
  final double earnedRoyaltyBalance;
  final double freeDailyBalance;
  final int totalGenerations;
  final double totalRoyaltiesEarned;

  WalletModel({
    required this.purchasedBalance,
    required this.earnedRoyaltyBalance,
    required this.freeDailyBalance,
    required this.totalGenerations,
    required this.totalRoyaltiesEarned,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      purchasedBalance: (json['purchased_balance'] as num?)?.toDouble() ?? 0.0,
      earnedRoyaltyBalance: (json['earned_royalty_balance'] as num?)?.toDouble() ?? 0.0,
      freeDailyBalance: (json['free_daily_balance'] as num?)?.toDouble() ?? 500.0,
      totalGenerations: (json['total_generations'] as num?)?.toInt() ?? 0,
      totalRoyaltiesEarned: (json['total_royalties_earned'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'purchased_balance': purchasedBalance,
      'earned_royalty_balance': earnedRoyaltyBalance,
      'free_daily_balance': freeDailyBalance,
      'total_generations': totalGenerations,
      'total_royalties_earned': totalRoyaltiesEarned,
    };
  }

  double get totalSpendable => purchasedBalance + earnedRoyaltyBalance + freeDailyBalance;
  bool get isEligibleForPayout => earnedRoyaltyBalance >= 25.0;
}
