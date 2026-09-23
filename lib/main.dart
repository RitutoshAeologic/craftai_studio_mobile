import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/constants/app_strings.dart';
import 'core/services/network_service.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/studio/domain/repositories/i_studio_repository.dart';
import 'features/studio/data/repositories/studio_repository_impl.dart';
import 'shared/widgets/offline_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();

  // Register NetworkService as permanent GetxService — monitors network state across the app.
  await Get.putAsync<NetworkService>(() => NetworkService().init(), permanent: true);

  // Register AuthController as permanent — alive for the full app session.
  // Every auth screen calls Get.find<AuthController>() instead of Get.put().
  Get.put(AuthController(), permanent: true);

  // Global repository bindings for studio & tools features
  Get.lazyPut<IStudioRepository>(() => StudioRepositoryImpl());

  runApp(const CraftAIStudioApp());
}

class CraftAIStudioApp extends StatelessWidget {
  const CraftAIStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          initialRoute: AppRoutes.splash,
          getPages: AppPages.pages,
          // Global snackbar / dialog theme matching dark neon palette.
          defaultTransition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 250),
          builder: (context, widget) {
            return OfflineBannerOverlay(
              child: widget ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
