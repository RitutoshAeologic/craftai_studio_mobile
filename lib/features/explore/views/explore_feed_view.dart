import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import '../controllers/explore_controller.dart';
import '../widgets/explore_card_widget.dart';

class ExploreFeedView extends StatelessWidget {
  const ExploreFeedView({super.key});

  @override
  Widget build(BuildContext context) {
    final ExploreController controller = Get.put(ExploreController());

    return Scaffold(
      body: Column(
        children: [
          // Category Pills
          Container(
            height: 48.h,
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Obx(() => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: controller.categories.length,
              itemBuilder: (context, idx) {
                final cat = controller.categories[idx];
                final isSelected = controller.selectedCategory.value == cat;
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: FilterChip(
                    label: Text(cat, style: TextStyle(fontSize: 12.sp, color: isSelected ? Colors.black : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    checkmarkColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r), side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border)),
                    onSelected: (_) => controller.setCategory(cat),
                  ),
                );
              },
            )),
          ),

          // Artwork Feed
          Expanded(
            child: Obx(() => ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              itemCount: controller.filteredCards.length,
              itemBuilder: (context, idx) {
                final card = controller.filteredCards[idx];
                return Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: ExploreCardWidget(card: card),
                );
              },
            )),
          ),
        ],
      ),
    );
  }
}
