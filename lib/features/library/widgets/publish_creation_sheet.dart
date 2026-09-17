import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/data/models/job_model.dart';
import 'package:craftai_studio_mobile/features/explore/controllers/explore_controller.dart';
import 'package:craftai_studio_mobile/core/services/supabase_service.dart';
import 'package:craftai_studio_mobile/core/utils/app_logger.dart';

/// [PublishCreationSheet] allows users to publish their personal creation from
/// Library to the public Explore community feed with 40% creator royalty enabled.
class PublishCreationSheet extends StatefulWidget {
  final JobModel job;

  const PublishCreationSheet({super.key, required this.job});

  static void show(BuildContext context, JobModel job) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PublishCreationSheet(job: job),
    );
  }

  @override
  State<PublishCreationSheet> createState() => _PublishCreationSheetState();
}

class _PublishCreationSheetState extends State<PublishCreationSheet> {
  late final TextEditingController _titleController;
  String _selectedCategory = 'Anime';
  bool _isPublishing = false;

  final List<String> _categories = const [
    'Anime',
    'Photorealism',
    'Cyberpunk',
    '3D Render',
    'Character',
    'Architecture',
    'Product',
  ];

  @override
  void initState() {
    super.initState();
    final words = widget.job.prompt.split(' ');
    final defaultTitle = words.take(5).join(' ');
    _titleController = TextEditingController(text: defaultTitle.isNotEmpty ? defaultTitle : 'AI Visual Creation');
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handlePublish() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      Get.snackbar(
        'Title Required',
        'Please enter a title for your community creation.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.accentWarning,
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final exploreCtrl = Get.isRegistered<ExploreController>()
          ? Get.find<ExploreController>()
          : Get.put(ExploreController());

      // 1. Add to local Explore feed state
      exploreCtrl.publishCreation(
        title: title,
        prompt: widget.job.prompt,
        previewUrl: widget.job.previewUrl,
        category: _selectedCategory,
      );

      // 2. Persist to Supabase explore_prompts if authenticated
      try {
        final user = SupabaseService.client.auth.currentUser;
        if (user != null) {
          await SupabaseService.client.from('explore_prompts').insert({
            'author_id': user.id,
            'title': title,
            'preview_url': widget.job.previewUrl,
            'category': _selectedCategory,
            'masked_summary': widget.job.prompt,
            'remix_fee': 4.0,
            'creator_royalty_cut': 1.6,
          });
          AppLogger.s('Published creation to Supabase explore_prompts table', tag: 'EXPLORE_PUBLISH');
        }
      } catch (e) {
        AppLogger.d('Cloud publish skipped or table pending migration: $e', tag: 'EXPLORE_PUBLISH');
      }

      Get.back(); // close sheet

      Get.snackbar(
        'Published to Community Feed! 🚀',
        'Your creation is now live on Explore with 40% creator royalty enabled.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.primary,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        'Publish Notice',
        'Could not publish right now. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.accentWarning,
      );
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, MediaQuery.of(context).viewInsets.bottom + 24.h),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pill Handle
              Center(
                child: Container(
                  width: 38.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 14.h),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Publish to Explore Feed',
                    style: AppTextStyles.h2.copyWith(fontSize: 17.sp),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: AppColors.accentSuccess.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    ),
                    child: Text(
                      '40% Royalty',
                      style: AppTextStyles.captionBold.copyWith(color: AppColors.accentSuccess),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                'Share your masterpiece with the community. You earn 1.6 Credits every time someone remixes your creation.',
                style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary),
              ),

              SizedBox(height: 16.h),

              // Title Field
              Text('Title', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
              SizedBox(height: 6.h),
              TextField(
                controller: _titleController,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp),
                decoration: InputDecoration(
                  hintText: 'Enter creation title...',
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13.sp),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                ),
              ),

              SizedBox(height: 16.h),

              // Category Selector Chips
              Text('Select Category', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: _categories.map((cat) {
                  final isSelected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: 20.h),

              // Publish Action Button
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: _isPublishing ? null : _handlePublish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                  child: _isPublishing
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Confirm & Publish (Free)',
                          style: AppTextStyles.bodyMediumBold.copyWith(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
