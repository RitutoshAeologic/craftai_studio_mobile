import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../network/api_config.dart';
import '../../data/models/credit_package_model.dart';

/// Callback signatures for payment lifecycle events
typedef OnPaymentSuccessCallback = void Function(PaymentSuccessResponse response);
typedef OnPaymentErrorCallback = void Function(PaymentFailureResponse response);
typedef OnExternalWalletCallback = void Function(ExternalWalletResponse response);

/// [PaymentService] handles Razorpay checkout SDK lifecycle and event dispatching.
/// Follows Clean Architecture and enables test mocking.
class PaymentService {
  Razorpay? _razorpay;
  bool _isInitialized = false;

  OnPaymentSuccessCallback? _onSuccess;
  OnPaymentErrorCallback? _onError;
  OnExternalWalletCallback? _onExternalWallet;

  /// Custom test handler override for widget testing
  static bool isTestMode = false;
  static Function(Map<String, dynamic> options)? mockCheckoutHandler;

  PaymentService() {
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      // Razorpay Flutter mobile plugin operates on Android & iOS
      return;
    }

    try {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
      _isInitialized = true;
    } catch (e) {
      debugPrint('[PAYMENT_SERVICE ⚠️] Razorpay init failed: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('[PAYMENT_SERVICE ✅] Success: ${response.paymentId}');
    _onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('[PAYMENT_SERVICE ❌] Error [${response.code}]: ${response.message}');
    _onError?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('[PAYMENT_SERVICE 💳] External Wallet: ${response.walletName}');
    _onExternalWallet?.call(response);
  }

  /// Opens the native Razorpay checkout overlay with package details
  void openCheckout({
    required CreditPackageModel package,
    required String userEmail,
    String? userPhone,
    required OnPaymentSuccessCallback onSuccess,
    required OnPaymentErrorCallback onError,
    required OnExternalWalletCallback onExternalWallet,
    String? razorpayOrderId,
  }) {
    _onSuccess = onSuccess;
    _onError = onError;
    _onExternalWallet = onExternalWallet;

    final options = <String, dynamic>{
      'key': ApiConfig.razorpayKeyId,
      'amount': package.amountInPaise,
      'name': 'CraftAI Studio',
      'description': '${package.name} (${package.totalCredits} Credits)',
      'currency': 'INR',
      'retry': {'enabled': true, 'max_count': 3},
      'send_sms_hash': true,
      'prefill': {
        'email': userEmail.isNotEmpty ? userEmail : 'creator@craftai.studio',
        'contact': userPhone ?? '',
      },
      'theme': {
        'color': '#6366F1', // AppColors.primary
      },
      'external': {
        'wallets': ['paytm', 'phonepe'],
      },
    };

    if (razorpayOrderId != null && razorpayOrderId.isNotEmpty) {
      options['order_id'] = razorpayOrderId;
    }

    if (isTestMode || mockCheckoutHandler != null) {
      mockCheckoutHandler?.call(options);
      return;
    }

    if (!_isInitialized || _razorpay == null) {
      _initializeRazorpay();
    }

    try {
      _razorpay?.open(options);
    } catch (e) {
      debugPrint('[PAYMENT_SERVICE ❌] Failed to open checkout: $e');
      onError(PaymentFailureResponse(
        Razorpay.UNKNOWN_ERROR,
        'Failed to launch payment checkout: $e',
        null,
      ));
    }
  }

  /// Releases Razorpay native resources
  void dispose() {
    try {
      _razorpay?.clear();
    } catch (e) {
      debugPrint('[PAYMENT_SERVICE ⚠️] Error clearing Razorpay: $e');
    }
    _onSuccess = null;
    _onError = null;
    _onExternalWallet = null;
  }

  /// Test harness helper to simulate Razorpay success callback
  @visibleForTesting
  void simulateSuccess(PaymentSuccessResponse response) {
    _handlePaymentSuccess(response);
  }

  /// Test harness helper to simulate Razorpay error / cancellation callback
  @visibleForTesting
  void simulateError(PaymentFailureResponse response) {
    _handlePaymentError(response);
  }

  /// Test harness helper to simulate Razorpay external wallet callback
  @visibleForTesting
  void simulateExternalWallet(ExternalWalletResponse response) {
    _handleExternalWallet(response);
  }
}

