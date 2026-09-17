import 'package:get/get.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/views/splash_view.dart';
import '../../features/auth/presentation/views/login_view.dart';
import '../../features/auth/presentation/views/signup_view.dart';
import '../../features/auth/presentation/views/forgot_password_view.dart';
import '../../features/shell/views/home_shell_view.dart';
import 'app_routes.dart';

/// Single source of truth for every named [GetPage] in the app.
/// Add new pages here — never create ad-hoc routes in widgets.
class AppPages {
  AppPages._();

  static const String initial = AppRoutes.splash;

  static final List<GetPage<dynamic>> pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
      // AuthController is permanent (registered in main.dart) — no binding needed.
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignupView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeShellView(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
      // Re-register AuthController binding for home so Get.find() works there too.
      binding: BindingsBuilder.put(() => Get.find<AuthController>()),
    ),
  ];
}
