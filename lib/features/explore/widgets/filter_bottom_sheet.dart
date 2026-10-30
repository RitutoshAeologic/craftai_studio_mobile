import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/features/explore/controllers/explore_controller.dart';

/// [FilterBottomSheet] provides multi-faceted filtering across Models, Tools, Categories,
/// and Aspect Ratios with Hick's Law compliance (1 Primary 'Apply Filters' CTA + Reset).
class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const FilterBottomSheet(),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  final ExploreController _controller = Get.find<ExploreController>();

  late String _tempCategory;
  final Set<String> _selectedAspectRatios = <String>{'All'};

  final List<String> _aspectRatios = ['All', '1:1', '16:9', '9:16', '4:5', '3:4'];
  final List<String> _models = ['All Models', 'SDXL-Lightning', 'FLUX.1 Schnell', 'RealVisXL v4.0'];
  String _selectedModel = 'All Models';

  @override
  void initState() {
    super.initState();
    _tempCategory = _controller.selectedCategory.value;
    _selectedModel = _controller.selectedModel.value;
    _selectedAspectRatios.clear();
    _selectedAspectRatios.addAll(_controller.selectedAspectRatios);
  }

  void _applyFilters() {
    HapticFeedback.mediumImpact();
    _controller.applyFilters(
      category: _tempCategory,
      model: _selectedModel,
      aspectRatios: _selectedAspectRatios,
    );
    Navigator.of(context).pop();
  }

  void _resetFilters() {
    HapticFeedback.lightImpact();
    setState(() {
      _tempCategory = 'All';
      _selectedModel = 'All Models';
      _selectedAspectRatios.clear();
      _selectedAspectRatios.add('All');
    });
    _controller.resetFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: 0.82.sh),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusXl)),
        border: Border.all(color: AppColors.border),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44.w,
                height: 5.h,
                margin: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                ),
              ),
            ),

            // Header Row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Feed',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: _resetFilters,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    child: Text(
                      'Reset All',
                      style: AppTextStyles.captionBold.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: AppColors.border),

            // Filter Options Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Categories
                    _buildSectionHeader('Category'),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: _controller.categories.map((cat) {
                        final isSelected = _tempCategory == cat;
                        return _buildSelectableChip(
                          label: cat,
                          isSelected: isSelected,
                          onTap: () => setState(() => _tempCategory = cat),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 20.h),

                    // Section 2: AI Models
                    _buildSectionHeader('AI Model'),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: _models.map((mod) {
                        final isSelected = _selectedModel == mod;
                        return _buildSelectableChip(
                          label: mod,
                          isSelected: isSelected,
                          onTap: () => setState(() => _selectedModel = mod),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 20.h),

                    // Section 3: Aspect Ratios
                    _buildSectionHeader('Aspect Ratio'),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: _aspectRatios.map((ratio) {
                        final isSelected = _selectedAspectRatios.contains(ratio);
                        return _buildSelectableChip(
                          label: ratio,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              if (ratio == 'All') {
                                _selectedAspectRatios.clear();
                                _selectedAspectRatios.add('All');
                              } else {
                                _selectedAspectRatios.remove('All');
                                if (isSelected) {
                                  _selectedAspectRatios.remove(ratio);
                                  if (_selectedAspectRatios.isEmpty) _selectedAspectRatios.add('All');
                                } else {
                                  _selectedAspectRatios.add(ratio);
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),

            // Sticky Bottom CTA Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    ),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.surface,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.bodyMediumBold.copyWith(
        color: AppColors.textPrimary,
        fontSize: 14.sp,
      ),
    );
  }

  Widget _buildSelectableChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppDimens.radiusRound),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppDimens.radiusRound),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.captionBold.copyWith(
            color: isSelected ? AppColors.surface : AppColors.textSecondary,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }
}
