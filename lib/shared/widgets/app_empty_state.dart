import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';
import 'app_button.dart';

/// [AppEmptyState] is a shared, reusable component displayed when a list, feed,
/// or gallery has no items. Mandated by rules.md §5.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  /// The illustrative icon to render in the center circle.
  final IconData icon;

  /// Primary headline text.
  final String title;

  /// Secondary descriptive text explaining what to do.
  final String subtitle;

  /// Optional call-to-action button label.
  final String? actionLabel;

  /// Optional callback when call-to-action button is pressed.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppDimens.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Icon(icon, color: AppColors.primary, size: 28.sp),
              ),
            ),
            SizedBox(height: AppDimens.vSpacingMd),
            Text(
              title,
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppDimens.vSpacingSm),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: AppDimens.vSpacingLg),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                width: 180.w,
                height: 42.h,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
