import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/data/models/explore_card_model.dart';
import '../controllers/explore_controller.dart';
import 'more_like_this_sheet.dart';

class ExploreCardWidget extends StatelessWidget {
  final ExploreCardModel card;
  const ExploreCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final ExploreController controller = Get.find<ExploreController>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Preview with Watermark & Tag
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                child: CachedNetworkImage(
                  imageUrl: card.previewUrl,
                  height: 240.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(height: 240.h, color: AppColors.surfaceLight),
                ),
              ),
              Positioned(
                top: 10.h,
                right: 10.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(card.category, style: TextStyle(color: AppColors.primary, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                ),
              ),
              Positioned(
                bottom: 8.h,
                right: 8.w,
                child: Text('CraftAI Preview', style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 10.sp, fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Royalty
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(card.title, style: TextStyle(color: AppColors.textPrimary, fontSize: 15.sp, fontWeight: FontWeight.bold)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppColors.accentSuccess.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text('40% Royalty', style: TextStyle(color: AppColors.accentSuccess, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text('By ${card.authorHandle} • AES-256 Protected', style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp)),
                SizedBox(height: 8.h),
                Text(card.maskedSummary, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp)),

                SizedBox(height: 12.h),
                // Dual Action Bar + More Like This Button
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => controller.useAsPrompt(card),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                          ),
                        ),
                        icon: Icon(Icons.edit_note, size: 16.sp),
                        label: Text('Use as Prompt', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => controller.useAsRef(card),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceLight,
                          foregroundColor: AppColors.textPrimary,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                        ),
                        icon: Icon(Icons.add_photo_alternate_outlined, size: 16.sp),
                        label: Text('Use as Ref', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    IconButton(
                      icon: const Icon(Icons.grid_view_rounded, color: AppColors.textSecondary),
                      onPressed: () {
                        Get.bottomSheet(MoreLikeThisSheet(referenceCard: card));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
