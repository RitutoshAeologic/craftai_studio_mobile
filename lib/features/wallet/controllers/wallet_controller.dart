import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/data/models/wallet_model.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';

class WalletController extends GetxController {
  final ShellController shellCtrl = Get.find<ShellController>();

  Rx<WalletModel> get wallet => shellCtrl.walletModel;

  @override
  void onInit() {
    super.onInit();
    shellCtrl.fetchWalletCredits();
  }

  void buyCreditPack(String name, double credits, double priceUsd) {
    shellCtrl.addCredits(credits, isPurchased: true);
    Get.snackbar(
      'Credit Pack Added! ✦',
      'Added ${credits.toInt()} credits to your purchased balance.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.primary,
    );
  }

  void requestPayout() {
    if (wallet.value.earnedRoyaltyBalance < 250.0) {
      Get.snackbar(
        'Minimum Payout Threshold',
        'Minimum withdrawal threshold is 250 credits (\$25.00 USD). Current earned balance: ${wallet.value.earnedRoyaltyBalance.toStringAsFixed(1)} credits.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.accentWarning,
      );
    } else {
      Get.snackbar(
        'Payout Initiated',
        'Transferring to your connected Stripe / PayPal account...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.primary,
      );
    }
  }
}
