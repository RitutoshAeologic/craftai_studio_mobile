import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/services/supabase_service.dart';
import 'package:craftai_studio_mobile/core/utils/app_logger.dart';
import 'package:craftai_studio_mobile/data/models/wallet_model.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';

/// [ShellController] manages the root navigation shell of the application.
///
/// Responsibilities:
/// - Tracks active bottom navigation tab index ([currentIndex])
/// - Holds reactive user wallet credits balance ([userCredits]) across all tabs
/// - Synchronizes credit state with Supabase wallets ledger
class ShellController extends GetxController {
  static ShellController get to => Get.find<ShellController>();

  /// Active tab index: 0 = Explore, 1 = Studio, 2 = AI Tools, 3 = Library, 4 = Profile.
  final RxInt currentIndex = 0.obs;

  /// Observable wallet credit balance.
  /// Initialized to 500.0 Cr for rapid development and testing.
  final RxDouble userCredits = 500.0.obs;

  /// Complete observable dual-ledger wallet model (purchased, royalties, free)
  final Rx<WalletModel> walletModel = WalletModel(
    purchasedBalance: 0.0,
    earnedRoyaltyBalance: 0.0,
    freeDailyBalance: 500.0,
    totalGenerations: 0,
    totalRoyaltiesEarned: 0.0,
  ).obs;

  @override
  void onInit() {
    super.onInit();
    fetchWalletCredits();
  }

  /// Fetches latest wallet balance from Supabase wallets table
  Future<void> fetchWalletCredits() async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        final res = await SupabaseService.client
            .from('wallets')
            .select('*')
            .eq('user_id', user.id)
            .maybeSingle();

        if (res != null) {
          final wallet = WalletModel.fromJson(res);
          walletModel.value = wallet;
          userCredits.value = wallet.totalSpendable;
          AppLogger.s('Synced wallet balance from Supabase: ${userCredits.value} Cr (Purchased: ${wallet.purchasedBalance}, Royalties: ${wallet.earnedRoyaltyBalance}, Free: ${wallet.freeDailyBalance})', tag: 'WALLET');
        } else {
          // Brand new user: auto-create wallet row in Supabase with initial 500 credits
          try {
            await SupabaseService.client.from('wallets').upsert({
              'user_id': user.id,
              'free_daily_balance': 500.0,
              'purchased_balance': 0.0,
              'earned_royalty_balance': 0.0,
              'credits': 500.0,
            }, onConflict: 'user_id');
            userCredits.value = 500.0;
            walletModel.value = WalletModel(
              purchasedBalance: 0.0,
              earnedRoyaltyBalance: 0.0,
              freeDailyBalance: 500.0,
              totalGenerations: 0,
              totalRoyaltiesEarned: 0.0,
            );
            AppLogger.s('Initialized new user wallet with 500.0 Cr in Supabase', tag: 'WALLET');
          } catch (_) {}
        }
      }
    } catch (e) {
      AppLogger.d('Wallet fetch skipped or table pending migration: $e', tag: 'WALLET');
    }
  }

  /// Programmatically switches the active bottom bar tab.
  /// [index]: 0 (Explore), 1 (Studio), 2 (AI Tools), 3 (Library), 4 (Profile).
  void switchTab(int index) {
    if (Get.isRegistered<StudioController>()) {
      final studioCtrl = Get.find<StudioController>();
      if (studioCtrl.isGenerating.value && index != 3) {
        Get.snackbar(
          'Generation in Progress ⏳',
          'Canvas is currently generating your artwork on GPU. Please wait a moment.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: AppColors.primary,
          duration: const Duration(seconds: 2),
        );
        return;
      }
    }
    currentIndex.value = index;
  }

  /// Deducts [amount] credits from the user's wallet.
  /// Automatically triggers reactive UI updates for credit badges and syncs to Supabase.
  void deductCredits(double amount) {
    if (userCredits.value >= amount) {
      userCredits.value -= amount;
      final current = walletModel.value;
      double remaining = amount;
      double newFree = current.freeDailyBalance;
      double newPurchased = current.purchasedBalance;
      double newRoyalty = current.earnedRoyaltyBalance;

      if (newFree >= remaining) {
        newFree -= remaining;
        remaining = 0;
      } else {
        remaining -= newFree;
        newFree = 0;
        if (newPurchased >= remaining) {
          newPurchased -= remaining;
          remaining = 0;
        } else {
          remaining -= newPurchased;
          newPurchased = 0;
          newRoyalty = (newRoyalty - remaining).clamp(0.0, double.infinity);
        }
      }

      walletModel.value = WalletModel(
        purchasedBalance: newPurchased,
        earnedRoyaltyBalance: newRoyalty,
        freeDailyBalance: newFree,
        totalGenerations: current.totalGenerations + 1,
        totalRoyaltiesEarned: current.totalRoyaltiesEarned,
      );
      _persistBalance();
    }
  }

  /// Adds [amount] credits to the user's wallet (e.g. after a pack purchase or reward).
  void addCredits(double amount, {bool isPurchased = false}) {
    userCredits.value += amount;
    final current = walletModel.value;
    walletModel.value = WalletModel(
      purchasedBalance: isPurchased ? current.purchasedBalance + amount : current.purchasedBalance,
      earnedRoyaltyBalance: current.earnedRoyaltyBalance,
      freeDailyBalance: isPurchased ? current.freeDailyBalance : current.freeDailyBalance + amount,
      totalGenerations: current.totalGenerations,
      totalRoyaltiesEarned: current.totalRoyaltiesEarned,
    );
    _persistBalance();
  }

  Future<void> _persistBalance() async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        final w = walletModel.value;
        await SupabaseService.client
            .from('wallets')
            .upsert({
              'user_id': user.id,
              'credits': userCredits.value,
              'free_daily_balance': w.freeDailyBalance,
              'purchased_balance': w.purchasedBalance,
              'earned_royalty_balance': w.earnedRoyaltyBalance,
              'total_generations': w.totalGenerations,
              'total_royalties_earned': w.totalRoyaltiesEarned,
              'updated_at': DateTime.now().toIso8601String(),
            }, onConflict: 'user_id');
      }
    } catch (_) {}
  }
}

