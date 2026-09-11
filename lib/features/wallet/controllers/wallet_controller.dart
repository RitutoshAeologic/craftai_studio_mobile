import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/data/models/wallet_model.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';

class WalletController extends GetxController {
  final Rx<WalletModel> wallet = WalletModel(
    purchasedBalance: 120.0,
    earnedRoyaltyBalance: 45.6,
    freeDailyBalance: 5.0,
    totalGenerations: 84,
    totalRoyaltiesEarned: 182.4,
  ).obs;

  void buyCreditPack(String name, double credits, double priceUsd) {
    final shellCtrl = Get.find<ShellController>();
    shellCtrl.addCredits(credits);
    wallet.value = WalletModel(
      purchasedBalance: wallet.value.purchasedBalance + credits,
      earnedRoyaltyBalance: wallet.value.earnedRoyaltyBalance,
      freeDailyBalance: wallet.value.freeDailyBalance,
      totalGenerations: wallet.value.totalGenerations,
      totalRoyaltiesEarned: wallet.value.totalRoyaltiesEarned,
    );
    Get.snackbar(
      'Credit Pack Added! ✦',
      'Added $credits credits to your purchased balance.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF151D2F),
      colorText: const Color(0xFF00F2FE),
    );
  }

  void requestPayout() {
    if (wallet.value.earnedRoyaltyBalance < 250.0) {
      Get.snackbar(
        'Minimum Payout Threshold',
        'Minimum withdrawal threshold is 250 credits (\$25.00 USD). Current earned balance: ${wallet.value.earnedRoyaltyBalance.toStringAsFixed(1)} credits.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF151D2F),
        colorText: Colors.amberAccent,
      );
    } else {
      Get.snackbar(
        'Payout Initiated',
        'Transferring to your connected Stripe / PayPal account...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF151D2F),
        colorText: const Color(0xFF00F2FE),
      );
    }
  }
}
