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

  double get totalSpendable => purchasedBalance + earnedRoyaltyBalance + freeDailyBalance;
  bool get isEligibleForPayout => earnedRoyaltyBalance >= 25.0;
}
