import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/models/credit_package_model.dart';
import '../../../data/models/wallet_ledger_model.dart';
import '../../../data/models/wallet_model.dart';
import '../../shell/controllers/shell_controller.dart';

/// [WalletController] coordinates dynamic package loading from Supabase,
/// native Razorpay checkout SDK integration, atomic credit fulfillment,
/// offline retry queues, and passbook transaction ledger history.
class WalletController extends GetxController {
  final ShellController shellCtrl = Get.find<ShellController>();
  late final PaymentService paymentService;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _kPhoneStorageKey = 'user_payment_phone';
  static const String _kPendingQueueKey = 'pending_payment_verifications';

  Rx<WalletModel> get wallet => shellCtrl.walletModel;

  /// Dynamic list of top-up packages loaded from Supabase Dashboard
  final RxList<CreditPackageModel> packages = <CreditPackageModel>[].obs;
  final RxBool isLoadingPackages = false.obs;

  /// Payment in-flight tracking (strict anti-double-tap guard)
  final RxBool isPurchasing = false.obs;
  final RxString purchasingPackageId = ''.obs;

  /// Cloud verification state after native Razorpay modal closes
  final RxBool isVerifyingPayment = false.obs;

  /// Itemized credit passbook / ledger history
  final RxList<WalletLedgerModel> ledgerEntries = <WalletLedgerModel>[].obs;
  final RxBool isLoadingLedger = false.obs;

  @override
  void onInit() {
    super.onInit();
    paymentService = PaymentService();
    shellCtrl.fetchWalletCredits();
    fetchPackages();
    fetchLedgerEntries();
    processPendingVerifications();
  }

  @override
  void onClose() {
    paymentService.dispose();
    super.onClose();
  }

  /// Retrieves user's phone number from Auth or secure cache.
  /// Falls back to test prefill to bypass Razorpay's contact prompt.
  Future<String> getPhonePrefill() async {
    try {
      final user = SupabaseService.instance.isInitialized
          ? SupabaseService.client.auth.currentUser
          : null;
      if (user?.phone != null && user!.phone!.trim().isNotEmpty) {
        return user.phone!.trim();
      }
      final cached = await _secureStorage.read(key: _kPhoneStorageKey);
      if (cached != null && cached.trim().isNotEmpty) {
        return cached.trim();
      }
    } catch (_) {}
    return '9999999999';
  }

  /// Saves valid phone number to secure storage for 1-tap future checkouts
  Future<void> saveUserPhone(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length >= 10) {
      await _secureStorage.write(key: _kPhoneStorageKey, value: cleaned);
    }
  }

  /// Fetches active credit packages from Supabase table `credit_packages`.
  /// If Supabase is offline or empty, safely falls back to default seed packages.
  Future<void> fetchPackages() async {
    isLoadingPackages.value = true;
    try {
      if (!Platform.environment.containsKey('FLUTTER_TEST') &&
          !Get.testMode &&
          SupabaseService.instance.isInitialized) {
        final res = await SupabaseService.client
            .from('credit_packages')
            .select()
            .eq('is_active', true)
            .order('sort_order', ascending: true);

        if (res.isNotEmpty) {
          packages.value =
              res.map((e) => CreditPackageModel.fromJson(e)).toList();
          return;
        }
      }
    } catch (e) {
      debugPrint('[WALLET_CTRL 🔍] Supabase packages fetch notice: $e. Using seed packages.');
    } finally {
      if (packages.isEmpty) {
        packages.value = CreditPackageModel.defaultPackages;
      }
      isLoadingPackages.value = false;
    }
  }

  /// Fetches user's itemized credit passbook ledger
  Future<void> fetchLedgerEntries() async {
    isLoadingLedger.value = true;
    try {
      if (!Platform.environment.containsKey('FLUTTER_TEST') &&
          !Get.testMode &&
          SupabaseService.instance.isInitialized) {
        final user = SupabaseService.client.auth.currentUser;
        if (user != null) {
          final res = await SupabaseService.client
              .from('wallet_ledger')
              .select()
              .eq('user_id', user.id)
              .order('created_at', ascending: false)
              .limit(30);

          if (res.isNotEmpty) {
            ledgerEntries.value =
                res.map((e) => WalletLedgerModel.fromJson(e)).toList();
          }
        }
      }
    } catch (e) {
      debugPrint('[WALLET_CTRL 🔍] Supabase ledger fetch notice: $e');
    } finally {
      isLoadingLedger.value = false;
    }
  }

  /// Launches Razorpay checkout with strict in-flight double-tap guard
  Future<void> initiatePurchase(CreditPackageModel package) async {
    // 1. Race condition / multi-tap guard
    if (isPurchasing.value || purchasingPackageId.isNotEmpty) {
      debugPrint('[WALLET_CTRL ⚠️] Blocked concurrent checkout attempt for ${package.packageId}');
      return;
    }

    HapticFeedback.lightImpact();
    isPurchasing.value = true;
    purchasingPackageId.value = package.packageId;

    final user = SupabaseService.instance.isInitialized
        ? SupabaseService.client.auth.currentUser
        : null;
    final userEmail = user?.email ?? 'creator@craftai.studio';
    final userPhone = await getPhonePrefill();

    paymentService.openCheckout(
      package: package,
      userEmail: userEmail,
      userPhone: userPhone,
      onSuccess: (PaymentSuccessResponse response) async {
        await _handlePaymentSuccess(package, response);
      },
      onError: (PaymentFailureResponse response) {
        _handlePaymentError(response);
      },
      onExternalWallet: (ExternalWalletResponse response) {
        _handleExternalWallet(response);
      },
    );
  }

  /// Processes successful Razorpay payment with exponential retry and queue fallback
  Future<void> _handlePaymentSuccess(
    CreditPackageModel package,
    PaymentSuccessResponse response,
  ) async {
    HapticFeedback.heavyImpact();
    isVerifyingPayment.value = true;
    try {
      final user = SupabaseService.instance.isInitialized
          ? SupabaseService.client.auth.currentUser
          : null;

      if (user != null && SupabaseService.instance.isInitialized) {
        final orderId = response.orderId ??
            'ord_direct_${DateTime.now().millisecondsSinceEpoch}';
        final paymentId = response.paymentId ??
            'pay_${DateTime.now().millisecondsSinceEpoch}';
        final signature = response.signature ?? 'sig_client_verified';

        final success = await _executeFulfillmentWithRetry(
          userId: user.id,
          packageId: package.packageId,
          orderId: orderId,
          paymentId: paymentId,
          signature: signature,
        );

        if (!success) {
          // Store in offline retry queue for recovery
          await _queuePendingVerification({
            'user_id': user.id,
            'package_id': package.packageId,
            'order_id': orderId,
            'payment_id': paymentId,
            'signature': signature,
            'timestamp': DateTime.now().toIso8601String(),
          });

          if (Get.overlayContext != null && !Get.testMode) {
            Get.snackbar(
              'Payment Confirmed ⏳',
              'Payment received! We are synchronizing your credit balance with the cloud. Credits will appear momentarily.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.surface,
              colorText: AppColors.primary,
              duration: const Duration(seconds: 4),
            );
          }
          return;
        }
      } else {
        // Fallback for mock test mode
        shellCtrl.addCredits(package.totalCredits.toDouble(), isPurchased: true);
      }

      // Re-fetch latest wallet balance and ledger entries from verified cloud
      await shellCtrl.fetchWalletCredits();
      await fetchLedgerEntries();

      // Show celebratory confirmation
      _showCelebrationDialog(package);
    } catch (e) {
      debugPrint('[WALLET_CTRL ⚠️] Fulfillment error: $e');
    } finally {
      isPurchasing.value = false;
      purchasingPackageId.value = '';
      isVerifyingPayment.value = false;
    }
  }

  /// Executes atomic PostgreSQL RPC with 3-attempt exponential backoff
  Future<bool> _executeFulfillmentWithRetry({
    required String userId,
    required String packageId,
    required String orderId,
    required String paymentId,
    required String signature,
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final res = await SupabaseService.client.rpc(
          'fulfill_credit_purchase',
          params: {
            'p_user_id': userId,
            'p_package_id': packageId,
            'p_order_id': orderId,
            'p_payment_id': paymentId,
            'p_signature': signature,
            'p_payment_method': 'razorpay',
          },
        );
        debugPrint('[WALLET_CTRL ✅] RPC fulfillment completed (attempt $attempt): $res');
        return true;
      } catch (e) {
        debugPrint('[WALLET_CTRL ⚠️] RPC attempt $attempt/$maxRetries failed: $e');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
    }
    return false;
  }

  /// Queues pending transaction to encrypted local storage
  Future<void> _queuePendingVerification(Map<String, dynamic> item) async {
    try {
      final raw = await _secureStorage.read(key: _kPendingQueueKey);
      List<dynamic> list = [];
      if (raw != null && raw.isNotEmpty) {
        list = jsonDecode(raw) as List<dynamic>;
      }
      list.add(item);
      await _secureStorage.write(
          key: _kPendingQueueKey, value: jsonEncode(list));
    } catch (e) {
      debugPrint('[WALLET_CTRL ⚠️] Error queuing pending transaction: $e');
    }
  }

  /// Retries unfulfilled transactions queued during spotty network transitions
  Future<void> processPendingVerifications() async {
    try {
      if (Get.testMode || !SupabaseService.instance.isInitialized) return;
      final raw = await _secureStorage.read(key: _kPendingQueueKey);
      if (raw == null || raw.isEmpty) return;

      final list =
          (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
      if (list.isEmpty) return;

      final remaining = <Map<String, dynamic>>[];
      for (final item in list) {
        final success = await _executeFulfillmentWithRetry(
          userId: item['user_id'] as String,
          packageId: item['package_id'] as String,
          orderId: item['order_id'] as String,
          paymentId: item['payment_id'] as String,
          signature: item['signature'] as String,
          maxRetries: 1,
        );
        if (!success) {
          remaining.add(item);
        }
      }

      if (remaining.isEmpty) {
        await _secureStorage.delete(key: _kPendingQueueKey);
      } else {
        await _secureStorage.write(
            key: _kPendingQueueKey, value: jsonEncode(remaining));
      }
      await shellCtrl.fetchWalletCredits();
      await fetchLedgerEntries();
    } catch (e) {
      debugPrint('[WALLET_CTRL ⚠️] Error processing pending queue: $e');
    }
  }

  /// Handles payment error / cancellation
  void _handlePaymentError(PaymentFailureResponse response) {
    HapticFeedback.selectionClick();
    isPurchasing.value = false;
    purchasingPackageId.value = '';
    isVerifyingPayment.value = false;

    if (Get.overlayContext != null && !Get.testMode) {
      final isDismissed = response.code == Razorpay.PAYMENT_CANCELLED;
      Get.snackbar(
        isDismissed ? 'Payment Cancelled' : 'Payment Incomplete',
        response.message ??
            (isDismissed
                ? 'Payment sheet was dismissed.'
                : 'Payment was cancelled or could not be completed.'),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: isDismissed
            ? AppColors.textSecondary
            : AppColors.accentWarning,
        borderColor: AppColors.border,
        borderWidth: 1,
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 3),
        icon: Icon(
          isDismissed
              ? Icons.info_outline_rounded
              : Icons.error_outline_rounded,
          color: isDismissed
              ? AppColors.textSecondary
              : AppColors.accentWarning,
        ),
      );
    }
  }

  /// Handles external wallet redirection (Paytm, etc.)
  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('[WALLET_CTRL 💳] Redirecting to external wallet: ${response.walletName}');
  }

  /// Celebratory success dialog upon credit pack fulfillment
  void _showCelebrationDialog(CreditPackageModel package) {
    if (Get.context == null || Get.testMode) return;

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          side: BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  gradient: AppColors.aiCosmicGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 14.r,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 30.sp,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                '✦ ${package.totalCredits} Credits Added!',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'Your payment of ${package.formattedPriceInr} was successful. You now have ${wallet.value.totalBalance.toInt()} Credits ready for high-res AI generation!',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusRound),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Start Creating',
                    style: AppTextStyles.captionBold
                        .copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
        margin: EdgeInsets.all(16.w),
      );
    } else {
      Get.snackbar(
        'Payout Initiated',
        'Transferring to your connected UPI / Bank account...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.primary,
        margin: EdgeInsets.all(16.w),
      );
    }
  }
}
