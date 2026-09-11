import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'core/constants/app_strings.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/views/home_shell_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
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
          home: const HomeShellView(),
        );
      },
    );
  }
}
