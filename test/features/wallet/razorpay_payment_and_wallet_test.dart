import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:craftai_studio_mobile/core/network/api_config.dart';
import 'package:craftai_studio_mobile/core/services/payment_service.dart';
import 'package:craftai_studio_mobile/data/models/credit_package_model.dart';
import 'package:craftai_studio_mobile/data/models/wallet_ledger_model.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/features/wallet/controllers/wallet_controller.dart';
import 'package:craftai_studio_mobile/features/wallet/views/wallet_view.dart';

Widget wrapWithScreenUtil(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (context, _) => GetMaterialApp(
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    Get.reset();
    PaymentService.isTestMode = true;
    PaymentService.mockCheckoutHandler = null;
  });

  tearDown(() {
    Get.reset();
    PaymentService.isTestMode = false;
    PaymentService.mockCheckoutHandler = null;
  });

  group('Use Case 1: Dynamic Credit Packages & Unit Economics', () {
    test('Calculates accurate paise, effective rates, and credits across all 4 tiers', () {
      final starter = CreditPackageModel.defaultPackages[0];
      final creator = CreditPackageModel.defaultPackages[1];
      final pro = CreditPackageModel.defaultPackages[2];
      final master = CreditPackageModel.defaultPackages[3];

      // Starter Tier (₹99 -> 100 Credits)
      expect(starter.packageId, 'pack_starter_99');
      expect(starter.amountInPaise, 9900);
      expect(starter.totalCredits, 100);
      expect(starter.bonusCredits, 0);
      expect(starter.effectiveRate, '₹0.99 / Cr');

      // Creator Tier (₹249 -> 300 Credits)
      expect(creator.packageId, 'pack_creator_249');
      expect(creator.amountInPaise, 24900);
      expect(creator.totalCredits, 300);
      expect(creator.bonusCredits, 50);
      expect(creator.isPopular, isTrue);
      expect(creator.effectiveRate, '₹0.83 / Cr');

      // Pro Tier (₹499 -> 650 Credits)
      expect(pro.packageId, 'pack_pro_499');
      expect(pro.amountInPaise, 49900);
      expect(pro.totalCredits, 650);
      expect(pro.bonusCredits, 150);
      expect(pro.effectiveRate, '₹0.77 / Cr');

      // Master Tier (₹999 -> 1500 Credits)
      expect(master.packageId, 'pack_master_999');
      expect(master.amountInPaise, 99900);
      expect(master.totalCredits, 1500);
      expect(master.bonusCredits, 500);
      expect(master.effectiveRate, '₹0.67 / Cr');
    });

    test('Parses Supabase credit_packages JSON response correctly', () {
      final supabaseRow = {
        'id': 'd290f1ee-6c54-4b01-90e6-d701748f0851',
        'package_id': 'pack_diwali_special_199',
        'name': 'Diwali Festive Pack',
        'badge': '50% EXTRA BONUS',
        'price_inr': 199.00,
        'price_usd': 2.49,
        'credits': 200,
        'bonus_credits': 100,
        'features': ['300 Total AI Credits', 'Exclusive Holiday Filters'],
        'is_popular': true,
        'is_active': true,
        'sort_order': 2,
      };

      final parsed = CreditPackageModel.fromJson(supabaseRow);
      expect(parsed.packageId, 'pack_diwali_special_199');
      expect(parsed.name, 'Diwali Festive Pack');
      expect(parsed.badge, '50% EXTRA BONUS');
      expect(parsed.amountInPaise, 19900);
      expect(parsed.totalCredits, 300);
      expect(parsed.effectiveRate, '₹0.66 / Cr');
      expect(parsed.isPopular, isTrue);
      expect(parsed.features.length, 2);
    });
  });

  group('Use Case 2: Passbook Ledger Model & Transaction Itemization', () {
    test('Correctly itemizes purchase credit vs generation debit', () {
      final purchaseEntry = WalletLedgerModel(
        id: 'led_tx_001',
        amount: 300.0,
        balanceAfter: 825.0,
        eventType: 'purchase',
        description: 'Top-up: Creator Pack (+300 Credits)',
        referenceId: 'pay_test_99812',
        createdAt: DateTime.now(),
      );

      final debitEntry = WalletLedgerModel(
        id: 'led_tx_002',
        amount: -2.0,
        balanceAfter: 823.0,
        eventType: 'generation',
        description: 'Generated Cyber Ronin (FLUX)',
        referenceId: 'task_88291',
        createdAt: DateTime.now(),
      );

      expect(purchaseEntry.isCredit, isTrue);
      expect(purchaseEntry.amount, 300.0);
      expect(purchaseEntry.referenceId, 'pay_test_99812');

      expect(debitEntry.isCredit, isFalse);
      expect(debitEntry.amount, -2.0);
    });
  });

  group('Use Case 3: 1-Tap Razorpay Options Payload Dispatch', () {
    test('Constructs standard Razorpay options payload with brand theme & paise', () {
      final paymentService = PaymentService();
      Map<String, dynamic>? capturedOptions;

      PaymentService.mockCheckoutHandler = (options) {
        capturedOptions = options;
      };

      final pkg = CreditPackageModel.defaultPackages[1]; // Creator pack ₹249

      paymentService.openCheckout(
        package: pkg,
        userEmail: 'vip.creator@craftai.studio',
        userPhone: '9876543210',
        onSuccess: (_) {},
        onError: (_) {},
        onExternalWallet: (_) {},
      );

      expect(capturedOptions, isNotNull);
      expect(capturedOptions!['key'], ApiConfig.razorpayKeyId);
      expect(capturedOptions!['amount'], 24900);
      expect(capturedOptions!['currency'], 'INR');
      expect(capturedOptions!['name'], 'CraftAI Studio');
      expect(capturedOptions!['description'], contains('Creator Pack'));
      expect(capturedOptions!['prefill']['email'], 'vip.creator@craftai.studio');
      expect(capturedOptions!['prefill']['contact'], '9876543210');
      expect(capturedOptions!['theme']['color'], '#6366F1');
      expect(capturedOptions!['retry']['enabled'], isTrue);
    });
  });

  group('Use Case 4: Happy Path Payment Success & Atomic Fulfillment', () {
    test('Simulated Razorpay success triggers wallet update and resets isPurchasing', () async {
      Get.put(ShellController());
      final walletController = Get.put(WalletController());

      final initialBalance = walletController.wallet.value.purchasedBalance;
      final testPackage = CreditPackageModel.defaultPackages[0]; // Starter ₹99 (100 credits)

      PaymentService.mockCheckoutHandler = (options) {
        // Mock handler does not re-enter checkout
      };

      await walletController.initiatePurchase(testPackage);
      expect(walletController.isPurchasing.value, isTrue);

      // Simulate payment success event from native SDK
      walletController.paymentService.simulateSuccess(
        PaymentSuccessResponse(
          'pay_test_success_9981',
          'order_test_9981',
          'signature_test_hash',
          {},
        ),
      );

      // Allow microtasks to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(walletController.isPurchasing.value, isFalse);
      expect(
        walletController.wallet.value.purchasedBalance,
        greaterThanOrEqualTo(initialBalance + testPackage.totalCredits),
      );
    });
  });

  group('Use Case 5: User Cancellation & Dismissal Handling', () {
    test('Payment cancellation resets isPurchasing and does NOT increment balance', () async {
      Get.put(ShellController());
      final walletController = Get.put(WalletController());

      final initialBalance = walletController.wallet.value.purchasedBalance;
      final testPackage = CreditPackageModel.defaultPackages[2]; // Pro Pack

      PaymentService.mockCheckoutHandler = (options) {};

      await walletController.initiatePurchase(testPackage);
      expect(walletController.isPurchasing.value, isTrue);

      // Simulate user closing / back-pressing Razorpay bottom sheet
      walletController.paymentService.simulateError(
        PaymentFailureResponse(
          Razorpay.PAYMENT_CANCELLED,
          'User closed payment sheet',
          null,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(walletController.isPurchasing.value, isFalse);
      // Balance remains strictly unchanged
      expect(walletController.wallet.value.purchasedBalance, initialBalance);
    });
  });

  group('Use Case 6: Gateway & Bank Decline Error Handling', () {
    test('Payment failure resets isPurchasing without crashing', () async {
      Get.put(ShellController());
      final walletController = Get.put(WalletController());

      final initialBalance = walletController.wallet.value.purchasedBalance;
      final testPackage = CreditPackageModel.defaultPackages[1];

      PaymentService.mockCheckoutHandler = (options) {};

      await walletController.initiatePurchase(testPackage);
      expect(walletController.isPurchasing.value, isTrue);

      // Simulate bank decline / network error
      walletController.paymentService.simulateError(
        PaymentFailureResponse(
          Razorpay.NETWORK_ERROR,
          'Payment declined by issuing bank',
          null,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(walletController.isPurchasing.value, isFalse);
      expect(walletController.wallet.value.purchasedBalance, initialBalance);
    });
  });

  group('Use Case 7: External Wallet Redirection Handling', () {
    test('External wallet event processes cleanly', () async {
      Get.put(ShellController());
      final walletController = Get.put(WalletController());

      final testPackage = CreditPackageModel.defaultPackages[0];
      PaymentService.mockCheckoutHandler = (options) {};

      await walletController.initiatePurchase(testPackage);

      // Simulate external wallet redirect (Paytm, etc.)
      walletController.paymentService.simulateExternalWallet(
        ExternalWalletResponse('paytm'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(walletController.isPurchasing.value, isTrue); // Remains until completion
    });
  });

  group('Use Case 8: WalletView Widget Rendering & Interaction Tests', () {
    testWidgets('renders balance overview, dynamic credit packs, and 1-tap Razorpay button', (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Get.put(ShellController());
      final walletController = Get.put(WalletController());
      walletController.packages.value = CreditPackageModel.defaultPackages;

      await tester.pumpWidget(wrapWithScreenUtil(const WalletView()));
      await tester.pump();

      // Check header
      expect(find.text('Wallet & Credits'), findsOneWidget);
      expect(find.text('Available Credit Balance'), findsOneWidget);
      expect(find.text('Purchased Credits'), findsOneWidget);
      expect(find.text('Buy Credit Packs'), findsOneWidget);
      expect(find.text('Instant UPI & Cards'), findsOneWidget);

      // Check dynamic packages rendered
      expect(find.text('Starter Pack'), findsOneWidget);
      expect(find.text('Creator Pack'), findsOneWidget);
      expect(find.text('Pro Studio Pack'), findsOneWidget);
      expect(find.text('Master Agency Pack'), findsOneWidget);

      // Check prices
      expect(find.text('₹99'), findsOneWidget);
      expect(find.text('₹249'), findsOneWidget);
      expect(find.text('₹499'), findsOneWidget);
      expect(find.text('₹999'), findsOneWidget);

      // Check badges
      expect(find.text('MOST POPULAR'), findsOneWidget);
      expect(find.text('BEST VALUE'), findsOneWidget);

      // Tap on buy button
      final buyButton = find.text('₹249').first;
      await tester.tap(buyButton);
      await tester.pump();
    });
  });

  group('Use Case 9: Race Condition Double-Tap Guard & In-Flight State Tracking', () {
    test('Rapid consecutive taps on packages are strictly deduplicated', () async {
      Get.put(ShellController());
      final walletController = Get.put(WalletController());

      int checkoutCallsCount = 0;
      PaymentService.mockCheckoutHandler = (options) {
        checkoutCallsCount++;
      };

      final starter = CreditPackageModel.defaultPackages[0];
      final creator = CreditPackageModel.defaultPackages[1];

      // Simulate rapid parallel taps
      final firstTap = walletController.initiatePurchase(starter);
      final secondTap = walletController.initiatePurchase(creator);

      await Future.wait([firstTap, secondTap]);

      // Exactly ONE checkout was dispatched
      expect(checkoutCallsCount, 1);
      expect(walletController.isPurchasing.value, isTrue);
      expect(walletController.purchasingPackageId.value, starter.packageId);

      // Clean up in-flight state
      walletController.isPurchasing.value = false;
      walletController.purchasingPackageId.value = '';
    });
  });

  group('Use Case 10: Phone Number Prefill & Secure Cache Retrieval', () {
    test('Retrieves phone prefill safely without throwing', () async {
      Get.put(ShellController());
      final walletController = Get.put(WalletController());

      final phone = await walletController.getPhonePrefill();
      expect(phone, isNotEmpty);
      expect(phone.length, greaterThanOrEqualTo(10));
    });
  });
}
