/// [CreditPackageModel] represents a top-up credit package loaded dynamically
/// from the Supabase `credit_packages` table or FastAPI backend.
/// Enables 100% remote price and bonus control from the Supabase Dashboard.
class CreditPackageModel {
  final String packageId;
  final String name;
  final String? badge;
  final double priceInr;
  final double priceUsd;
  final int credits;
  final int bonusCredits;
  final List<String> features;
  final bool isPopular;
  final bool isActive;
  final int sortOrder;

  const CreditPackageModel({
    required this.packageId,
    required this.name,
    this.badge,
    required this.priceInr,
    required this.priceUsd,
    required this.credits,
    this.bonusCredits = 0,
    this.features = const [],
    this.isPopular = false,
    this.isActive = true,
    this.sortOrder = 1,
  });

  /// Total credits granted (Base credits + Promotional bonus credits)
  int get totalCredits => credits + bonusCredits;

  /// Clean display price in INR (e.g. "₹249")
  String get formattedPriceInr => '₹${priceInr.toInt()}';

  /// Clean display price in USD (e.g. "$2.99")
  String get formattedPriceUsd => '\$${priceUsd.toStringAsFixed(2)}';

  /// Effective cost per credit (e.g. "₹0.83 / Cr")
  String get effectiveRate {
    if (totalCredits <= 0) return '₹0.00 / Cr';
    final rate = priceInr / totalCredits;
    return '₹${rate.toStringAsFixed(2)} / Cr';
  }

  /// Amount in paise for Razorpay order processing (e.g. ₹249.00 -> 24900 paise)
  int get amountInPaise => (priceInr * 100).round();

  factory CreditPackageModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedFeatures = [];
    if (json['features'] != null) {
      if (json['features'] is List) {
        parsedFeatures = (json['features'] as List)
            .map((e) => e.toString())
            .toList();
      }
    }

    return CreditPackageModel(
      packageId: json['package_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Credit Pack',
      badge: json['badge']?.toString(),
      priceInr: (json['price_inr'] as num?)?.toDouble() ?? 99.0,
      priceUsd: (json['price_usd'] as num?)?.toDouble() ?? 1.29,
      credits: (json['credits'] as num?)?.toInt() ?? 100,
      bonusCredits: (json['bonus_credits'] as num?)?.toInt() ?? 0,
      features: parsedFeatures,
      isPopular: json['is_popular'] == true,
      isActive: json['is_active'] != false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'package_id': packageId,
      'name': name,
      'badge': badge,
      'price_inr': priceInr,
      'price_usd': priceUsd,
      'credits': credits,
      'bonus_credits': bonusCredits,
      'features': features,
      'is_popular': isPopular,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  /// Default seed packages used when Supabase is offline or not yet migrated
  static List<CreditPackageModel> get defaultPackages => const [
        CreditPackageModel(
          packageId: 'pack_starter_99',
          name: 'Starter Pack',
          badge: 'Quick Trial',
          priceInr: 99.0,
          priceUsd: 1.29,
          credits: 100,
          bonusCredits: 0,
          features: [
            '50 High-Res Generations',
            'FLUX & SDXL Access',
            'InstantID Character Lock',
            'Community Publishing',
          ],
          isPopular: false,
          sortOrder: 1,
        ),
        CreditPackageModel(
          packageId: 'pack_creator_249',
          name: 'Creator Pack',
          badge: 'Most Popular',
          priceInr: 249.0,
          priceUsd: 2.99,
          credits: 250,
          bonusCredits: 50,
          features: [
            '150 High-Res Generations',
            '50 Free Bonus Credits',
            '4K Lossless Downloads',
            'Commercial Usage Rights',
            'Fast Queue Priority',
          ],
          isPopular: true,
          sortOrder: 2,
        ),
        CreditPackageModel(
          packageId: 'pack_pro_499',
          name: 'Pro Studio Pack',
          badge: 'Best Value',
          priceInr: 499.0,
          priceUsd: 5.99,
          credits: 500,
          bonusCredits: 150,
          features: [
            '325 High-Res Generations',
            '150 Free Bonus Credits',
            'Unlimited 4K Upscaling',
            'All AI Editing Tools Included',
            'Instant Support',
          ],
          isPopular: false,
          sortOrder: 3,
        ),
        CreditPackageModel(
          packageId: 'pack_master_999',
          name: 'Master Agency Pack',
          badge: 'Max Power',
          priceInr: 999.0,
          priceUsd: 11.99,
          credits: 1000,
          bonusCredits: 500,
          features: [
            '750 High-Res Generations',
            '500 Mega Bonus Credits',
            'Full Commercial License',
            'Zero Watermark',
            'VIP Generation Server',
          ],
          isPopular: false,
          sortOrder: 4,
        ),
      ];
}

