import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/network_service.dart';

/// Global non-blocking offline and connection-restored animated banner overlay.
///
/// Attached to the root [GetMaterialApp.builder] in `main.dart` so it floats
/// seamlessly over any screen in the application.
class OfflineBannerOverlay extends StatelessWidget {
  const OfflineBannerOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Obx(() {
              if (!Get.isRegistered<NetworkService>()) {
                return const SizedBox.shrink();
              }

              final network = NetworkService.to;
              final isOffline = network.showOfflineBanner.value;
              final isRestored = network.showRestoredBanner.value;

              if (!isOffline && !isRestored) {
                return const SizedBox.shrink();
              }

              final isSuccess = isRestored && !isOffline;
              final bgColor = isSuccess
                  ? const Color(0xFF14291D)
                  : const Color(0xFF2B1414);
              final borderColor = isSuccess
                  ? AppColors.accentSuccess.withValues(alpha: 0.6)
                  : AppColors.accentError.withValues(alpha: 0.6);
              final iconColor = isSuccess
                  ? AppColors.accentSuccess
                  : AppColors.accentError;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: borderColor, width: 1.w),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSuccess
                              ? Icons.wifi_rounded
                              : Icons.wifi_off_rounded,
                          color: iconColor,
                          size: 18.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isSuccess ? 'Back Online' : 'No Internet Connection',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              isSuccess
                                  ? 'Connection restored. Synced and ready.'
                                  : 'Offline mode active. Check Wi-Fi or data.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (!isSuccess)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => network.checkInternetReachability(),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 5.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white10,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Obx(
                              () => network.isCheckingReachability.value
                                  ? SizedBox(
                                      width: 12.w,
                                      height: 12.w,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5.w,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                          Colors.white70,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Retry',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      if (!isSuccess) SizedBox(width: 6.w),
                      if (!isSuccess)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: network.dismissOfflineBanner,
                          child: Padding(
                            padding: EdgeInsets.all(4.w),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white54,
                              size: 16.sp,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
