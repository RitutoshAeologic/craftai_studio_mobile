import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/services/supabase_service.dart';
import 'package:craftai_studio_mobile/core/utils/app_logger.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';

/// [ShellController] manages the root navigation shell of the application.
///
/// Responsibilities:
/// - Tracks active bottom navigation tab index ([currentIndex])
/// - Holds reactive user wallet credits balance ([userCredits]) across all tabs
/// - Synchronizes credit state with Supabase wallets ledger
class ShellController extends GetxController {
  static ShellController get to => Get.find<ShellController>();

  /// Active tab index: 0 = Explore, 1 = Studio, 2 = AI Tools, 3 = Library, 4 = Wallet.
  final RxInt currentIndex = 0.obs;

  /// Observable wallet credit balance.
  /// Initialized to 500.0 Cr for rapid development and testing.
  final RxDouble userCredits = 500.0.obs;

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
          final freeBal = (res['free_daily_balance'] as num?)?.toDouble() ?? 500.0;
          final purBal = (res['purchased_balance'] as num?)?.toDouble() ?? 0.0;
          userCredits.value = freeBal + purBal;
          AppLogger.s('Synced wallet balance from Supabase: ${userCredits.value} Cr', tag: 'WALLET');
        }
      }
    } catch (e) {
      AppLogger.d('Wallet fetch skipped or table pending migration: $e', tag: 'WALLET');
    }
  }

  /// Programmatically switches the active bottom bar tab.
  /// [index]: 0 (Explore), 1 (Studio), 2 (AI Tools), 3 (Library), 4 (Wallet).
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
      _persistBalance();
    }
  }

  /// Adds [amount] credits to the user's wallet (e.g. after a pack purchase or reward).
  void addCredits(double amount) {
    userCredits.value += amount;
    _persistBalance();
  }

  Future<void> _persistBalance() async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        await SupabaseService.client
            .from('wallets')
            .update({'free_daily_balance': userCredits.value})
            .eq('user_id', user.id);
      }
    } catch (_) {}
  }
}

