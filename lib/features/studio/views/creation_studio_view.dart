import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import '../controllers/studio_controller.dart';

class CreationStudioView extends StatelessWidget {
  const CreationStudioView({super.key});

  @override
  Widget build(BuildContext context) {
    final StudioController controller = Get.put(StudioController());

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prompt Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.border),
              ),
              padding: EdgeInsets.all(12.w),
              child: Column(
                children: [
                  TextField(
                    controller: controller.promptController,
                    maxLines: 3,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp),
                    decoration: InputDecoration(
                      hintText: 'Describe your scene (e.g. samurai girl in neon city, volumetric light)...',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13.sp),
                      border: InputBorder.none,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: controller.enhancePrompt,
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.surfaceLight,
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        ),
                        icon: Icon(Icons.auto_awesome, color: AppColors.primary, size: 14.sp),
                        label: Text('Enhance', style: TextStyle(color: AppColors.primary, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(width: 8.w),
                      TextButton.icon(
                        onPressed: controller.aiEditSubjectLock,
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.surfaceLight,
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        ),
                        icon: Icon(Icons.lock_outline, color: Colors.purpleAccent, size: 14.sp),
                        label: Text('AI Edit', style: TextStyle(color: Colors.purpleAccent, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),
            // Consistent Character & Reference Slots
            Text('Consistent Character & References', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            SizedBox(height: 8.h),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.face_retouching_natural, color: AppColors.primary, size: 18.sp),
                      SizedBox(width: 6.w),
                      Text('Aria Stark (3-Angle Face Lock)', style: TextStyle(fontSize: 12.sp, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),
            // Studio Interactive Controls Bar
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Studio Controls', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  SizedBox(height: 12.h),

                  // Batch Count & Seed Lock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Batch Count', style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted)),
                          SizedBox(height: 6.h),
                          Obx(() => Row(
                            children: [1, 2, 3, 4].map((n) {
                              final isSel = controller.batchCount.value == n;
                              return GestureDetector(
                                onTap: () => controller.setBatchCount(n),
                                child: Container(
                                  width: 32.w,
                                  height: 32.w,
                                  margin: EdgeInsets.only(right: 6.w),
                                  decoration: BoxDecoration(
                                    color: isSel ? AppColors.primary : AppColors.surfaceLight,
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Center(
                                    child: Text('$n', style: TextStyle(color: isSel ? Colors.black : AppColors.textPrimary, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              );
                            }).toList(),
                          )),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Seed Lock', style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted)),
                          SizedBox(height: 6.h),
                          Obx(() => GestureDetector(
                            onTap: controller.toggleSeedLock,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: controller.isSeedLocked.value ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceLight,
                                border: Border.all(color: controller.isSeedLocked.value ? AppColors.primary : AppColors.border),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.lock, color: controller.isSeedLocked.value ? AppColors.primary : AppColors.textMuted, size: 14.sp),
                                  SizedBox(width: 4.w),
                                  Text(controller.isSeedLocked.value ? 'Locked (🔒)' : 'Random', style: TextStyle(fontSize: 12.sp, color: controller.isSeedLocked.value ? AppColors.primary : AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          )),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),
                  // Aspect Ratio Selector
                  Text('Aspect Ratio', style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted)),
                  SizedBox(height: 6.h),
                  Obx(() => Wrap(
                    spacing: 8.w,
                    children: controller.aspectRatios.map((ratio) {
                      final isSel = controller.selectedAspectRatio.value == ratio;
                      return ChoiceChip(
                        label: Text(ratio, style: TextStyle(fontSize: 11.sp, color: isSel ? Colors.black : AppColors.textSecondary)),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceLight,
                        onSelected: (_) => controller.setAspectRatio(ratio),
                      );
                    }).toList(),
                  )),

                  SizedBox(height: 16.h),
                  // Resolution Selector
                  Text('Resolution', style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted)),
                  SizedBox(height: 6.h),
                  Obx(() => Row(
                    children: controller.resolutions.map((res) {
                      final isSel = controller.selectedResolution.value == res;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => controller.setResolution(res),
                          child: Container(
                            height: 32.h,
                            margin: EdgeInsets.only(right: 6.w),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.secondary : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Center(
                              child: Text(res, style: TextStyle(color: isSel ? Colors.black : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12.sp)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )),
                ],
              ),
            ),

            SizedBox(height: 24.h),
            // Sticky Generate Button
            Obx(() => SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton.icon(
                onPressed: controller.isGenerating.value ? null : controller.generateVisual,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                icon: controller.isGenerating.value
                    ? SizedBox(width: 16.w, height: 16.w, child: const CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  controller.isGenerating.value ? 'Generating on GPU...' : 'Generate ✨ ${controller.calculatedCreditCost} Credits',
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
