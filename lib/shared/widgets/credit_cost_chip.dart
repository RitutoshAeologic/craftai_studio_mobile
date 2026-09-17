import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';

/// [CreditCostChip] is a shared, reusable credit badge component used across
/// HomeShell, CreationStudio, CloudLibrary, and Bottom Sheets per rules.md §5.
///
/// Features:
/// - Supports reactive [RxDouble] balance or static [double]/[int] cost
/// - Visual glow and cyan branding accent
/// - Optional [onTap] handler (e.g. opens Wallet tab)
class CreditCostChip extends StatelessWidget {
  const CreditCostChip({
    super.key,
    this.creditsRx,
    this.staticCredits,
    this.onTap,
    this.showIcon = true,
    this.customIcon,
    this.isHighlighted = false,
    this.padding,
  });

  /// Optional reactive balance observable (e.g. from [ShellController]).
  final RxDouble? creditsRx;

  /// Optional static credits amount (e.g. '2 Cr' cost for generation).
  final double? staticCredits;

  /// Optional callback when the chip is tapped.
  final VoidCallback? onTap;

  /// Whether to display the leading sparkle icon.
  final bool showIcon;

  /// Optional custom icon override.
  final IconData? customIcon;

  /// Whether to highlight the chip with a primary border/background.
  final bool isHighlighted;

  /// Optional custom padding override.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ??
        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h);

    Widget buildContent(double amount) {
      final text = amount == amount.roundToDouble()
          ? '${amount.toInt()} ${AppStrings.cr}'
          : '${amount.toStringAsFixed(1)} ${AppStrings.cr}';

      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: effectivePadding,
          decoration: BoxDecoration(
            color: isHighlighted
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusRound),
            border: Border.all(
              color: isHighlighted
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                Icon(
                  customIcon ?? Icons.auto_awesome,
                  color: AppColors.primary,
                  size: 13.sp,
                ),
                SizedBox(width: 4.w),
              ],
              Text(
                text,
                style: AppTextStyles.captionBold.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (creditsRx != null) {
      return Obx(() => buildContent(creditsRx!.value));
    }

    return buildContent(staticCredits ?? 0.0);
  }
}
