import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/data/models/job_model.dart';
import 'package:craftai_studio_mobile/data/models/collection_model.dart';
import '../controllers/library_controller.dart';
import '../controllers/collection_controller.dart';
import '../views/creation_detail_view.dart';
import '../views/collection_gallery_view.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../shell/controllers/shell_controller.dart';

/// [CloudLibraryView] displays the user's personal creations backed up in the cloud.
/// Features bounded chunk pagination, infinite scrolling, pull-to-refresh,
/// contextual loaders, error recovery, and safe delete dialogs.
class CloudLibraryView extends StatefulWidget {
  const CloudLibraryView({super.key});

  @override
  State<CloudLibraryView> createState() => _CloudLibraryViewState();
}

class _CloudLibraryViewState extends State<CloudLibraryView> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ScrollController _scrollController;
  late final LibraryController _controller;
  late final CollectionController _collectionController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _controller = Get.put(LibraryController());
    _collectionController = Get.isRegistered<CollectionController>()
        ? Get.find<CollectionController>()
        : Get.put(CollectionController());
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Trigger next page when scrolling within 200px of bottom
    if (currentScroll >= maxScroll - 200) {
      if (!_controller.isLoadingMore.value &&
          _controller.hasMoreCreations.value &&
          _controller.libraryError.value == null &&
          !_controller.isLoading.value) {
        _controller.loadMoreCreations();
      }
    }
  }

  String _formatJobDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      final mins = difference.inMinutes.clamp(1, 59);
      return '${mins}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Cloud Library',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.h),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                height: 36.h,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                  border: Border.all(color: AppColors.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: AppTextStyles.captionBold.copyWith(fontSize: 12.5.sp),
                  unselectedLabelStyle: AppTextStyles.captionBold.copyWith(fontSize: 12.5.sp),
                  tabs: const [
                    Tab(text: 'Current'),
                    Tab(text: 'Collections'),
                  ],
                ),
              ),
              Container(color: AppColors.border, height: 1.h),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCurrentTab(),
          _buildCollectionsTab(),
        ],
      ),
    );
  }

  /// Tab 1: Current personal creations list with infinite scroll & pagination
  Widget _buildCurrentTab() {
    return Obx(() {
      // 1. Initial skeleton loading state
      if (_controller.isLoading.value && _controller.myCreations.isEmpty) {
        return _buildInitialSkeleton();
      }

      // 2. Empty library state
      if (_controller.myCreations.isEmpty) {
        return AppEmptyState(
          icon: Icons.photo_library_outlined,
          title: 'No Creations Yet',
          subtitle: 'Generate your first masterpiece in the Studio canvas.',
          actionLabel: 'Create Now',
          onAction: () {
            HapticFeedback.lightImpact();
            Get.find<ShellController>().switchTab(1);
          },
        );
      }

      // 3. Paginated creations list with pull-to-refresh
      return RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: _controller.refreshCreations,
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          itemCount: _controller.myCreations.length + 1,
          itemBuilder: (context, idx) {
            // Last item is the dynamic pagination footer
            if (idx == _controller.myCreations.length) {
              return _buildPaginationFooter();
            }

            final job = _controller.myCreations[idx];
            return _buildCreationCard(context, job);
          },
        ),
      );
    });
  }

  /// Tab 2: User-created Collections organizing saved artwork
  Widget _buildCollectionsTab() {
    return Obx(() {
      if (_collectionController.isLoading.value && _collectionController.collections.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 32.w,
                height: 32.w,
                child: const CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
              ),
              SizedBox(height: 16.h),
              Text(
                'Syncing collections...',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      }

      if (_collectionController.collections.isEmpty) {
        return AppEmptyState(
          icon: Icons.bookmark_border_rounded,
          title: 'No Collections Yet',
          subtitle: 'Create folders to organize your saved and bookmarked creations.',
          actionLabel: 'Create Collection',
          onAction: () => _showCreateCollectionDialog(context),
        );
      }

      return RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: _collectionController.fetchCollections,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${_collectionController.collections.length} Collections',
                    style: AppTextStyles.captionBold.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: () => _showCreateCollectionDialog(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 14.sp, color: AppColors.primary),
                        SizedBox(width: 4.w),
                        Text(
                          'New Collection',
                          style: AppTextStyles.captionBold.copyWith(
                            color: AppColors.primary,
                            fontSize: 11.5.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ..._collectionController.collections.map((col) => _buildCollectionCard(context, col)),
          ],
        ),
      );
    });
  }

  /// Card item displaying a collection folder and thumbnail previews of its saved images
  Widget _buildCollectionCard(BuildContext context, CollectionModel col) {
    return Obx(() {
      final items = _collectionController.getCollectionItems(col.id);
      final count = items.isNotEmpty ? items.length : col.itemCount;

      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Get.to(() => CollectionGalleryView(collection: col));
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                          ),
                          child: Icon(Icons.folder_open_rounded, color: AppColors.primary, size: 16.sp),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            col.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.h3.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '$count photo${count == 1 ? '' : 's'}',
                      style: AppTextStyles.captionXs.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18.sp),
                ],
              ),
              if (col.description != null && col.description!.isNotEmpty) ...[
                SizedBox(height: 6.h),
                Text(
                  col.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
                ),
              ],
              SizedBox(height: 10.h),
              if (items.isNotEmpty) ...[
                SizedBox(
                  height: 72.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: items.length.clamp(0, 6),
                    separatorBuilder: (_, __) => SizedBox(width: 8.w),
                    itemBuilder: (context, idx) {
                      final item = items[idx];
                      final imgUrl = item['image_url'] as String? ?? '';
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        child: Container(
                          width: 72.h,
                          height: 72.h,
                          color: AppColors.surfaceLight,
                          child: CachedNetworkImage(
                            imageUrl: imgUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppColors.surfaceLight),
                            errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: AppColors.textMuted),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else if (col.coverImageUrl != null && col.coverImageUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  child: Container(
                    height: 64.h,
                    width: double.infinity,
                    color: AppColors.surfaceLight,
                    child: CachedNetworkImage(
                      imageUrl: col.coverImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.surfaceLight),
                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: AppColors.textMuted),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                  child: Center(
                    child: Text(
                      'Empty collection • Tap to browse or add photos',
                      style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  void _showCreateCollectionDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        backgroundColor: AppColors.surface,
        child: Padding(
          padding: EdgeInsets.all(AppDimens.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('New Collection', style: AppTextStyles.h3),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(Icons.close, color: AppColors.textMuted),
                  ),
                ],
              ),
              SizedBox(height: AppDimens.vSpacingSm),
              Text(
                'Organize your saved artwork into custom themes.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              SizedBox(height: AppDimens.vSpacingMd),
              TextField(
                controller: nameController,
                autofocus: true,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Collection Name (e.g. Cyberpunk Vibes)',
                  hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                ),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: descController,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Description (optional)',
                  hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                ),
              ),
              SizedBox(height: AppDimens.vSpacingLg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text('Cancel', style: AppTextStyles.buttonSmall.copyWith(color: AppColors.textMuted)),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;
                      Get.back();
                      await _collectionController.createCollection(
                        name: name,
                        description: descController.text.trim(),
                      );
                      Get.snackbar(
                        'Collection Created',
                        '"$name" added to your collections',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.surface,
                        colorText: AppColors.primary,
                        duration: const Duration(seconds: 2),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      ),
                    ),
                    child: Text('Create', style: AppTextStyles.buttonSmall),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Initial loading indicator during first cloud sync
  Widget _buildInitialSkeleton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32.w,
            height: 32.w,
            child: const CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Syncing cloud library...',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Artwork creation card with image preview, cloud status pill, and actions
  Widget _buildCreationCard(BuildContext context, JobModel job) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Get.to(() => CreationDetailView(job: job));
                },
                child: AppNetworkImage(
                  imageUrl: (job.previewUrl.isNotEmpty && job.previewUrl.startsWith('http'))
                      ? job.previewUrl
                      : 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=600&auto=format&fit=crop',
                  height: 180.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
                ),
              ),

              // Creation timestamp badge (Top-left)
              Positioned(
                top: 8.h,
                left: 8.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                  ),
                  child: Text(
                    _formatJobDate(job.createdAt),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Delete button (Top-right)
              Positioned(
                top: 8.h,
                right: 8.w,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _confirmDelete(context, _controller, job);
                  },
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.accentError,
                      size: 18.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.prompt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_done_rounded,
                            size: 13.sp,
                            color: AppColors.accentSuccess,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Cloud Saved',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.accentSuccess,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Get.to(() => CreationDetailView(job: job));
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      label: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10.sp,
                        color: AppColors.primary,
                      ),
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

  /// Dynamic bottom footer for pagination loading, error retry, or end-of-list chip
  Widget _buildPaginationFooter() {
    return Obx(() {
      // 1. Actively loading older creations
      if (_controller.isLoadingMore.value) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16.w,
                height: 16.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'Loading earlier creations...',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }

      // 2. Pagination network or cloud error with 1-tap retry button
      if (_controller.libraryError.value != null) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          alignment: Alignment.center,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.lightImpact();
              _controller.loadMoreCreations();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                border: Border.all(color: AppColors.accentWarning.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 15.sp, color: AppColors.accentWarning),
                  SizedBox(width: 6.w),
                  Flexible(
                    child: Text(
                      'Failed to load older creations • Tap to retry',
                      style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // 3. Reached end of cloud library
      if (!_controller.hasMoreCreations.value && _controller.myCreations.isNotEmpty) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          alignment: Alignment.center,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppDimens.radiusRound),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_done_rounded, size: 13.sp, color: AppColors.accentSuccess),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    'All ${_controller.myCreations.length} cloud creations loaded ☁️',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return SizedBox(height: 16.h);
    });
  }

  /// Safe delete confirmation dialog
  void _confirmDelete(BuildContext context, LibraryController controller, JobModel job) {
    bool isDeleting = false;
    Get.dialog(
      StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return Dialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.accentError.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.delete_forever_rounded, color: AppColors.accentError, size: 28.sp),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Delete Creation?',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Permanently remove this creation from your cloud library and storage? This cannot be undone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.sp,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isDeleting ? null : () => Navigator.of(dialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isDeleting
                              ? null
                              : () async {
                                  setDialogState(() {
                                    isDeleting = true;
                                  });
                                  await controller.deleteCreation(job, showSnackbar: false);
                                  if (dialogContext.mounted) {
                                    Navigator.of(dialogContext).pop();
                                  }
                                  if (Get.overlayContext != null && !Get.testMode) {
                                    Get.snackbar(
                                      'Image Deleted 🗑️',
                                      'Image removed from your library and cloud storage.',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: AppColors.surface,
                                      colorText: AppColors.textPrimary,
                                      icon: const Icon(Icons.check_circle_rounded, color: AppColors.accentSuccess),
                                      margin: const EdgeInsets.all(16),
                                      borderRadius: 12,
                                      duration: const Duration(seconds: 2),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentError,
                            foregroundColor: AppColors.white,
                            disabledBackgroundColor: AppColors.accentError.withValues(alpha: 0.6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                          child: isDeleting
                              ? SizedBox(
                                  width: 18.w,
                                  height: 18.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                                  ),
                                )
                              : Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
