import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint("Supabase init note: $e");
  }
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
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.background,
            primaryColor: AppColors.primary,
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          ),
          home: const MainNavigationShell(),
        );
      },
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ExploreFeedScreen(),
    CreationStudioScreen(),
    CloudLibraryScreen(),
    WalletScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'Studio'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: 'Library'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
        ],
      ),
    );
  }
}

class ExploreFeedScreen extends StatelessWidget {
  const ExploreFeedScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.appName, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.primary)),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Center(
        child: Text("Explore & Prompt Discovery Feed\n(Powered by Supabase pgvector)", textAlign: TextAlign.center, style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary)),
      ),
    );
  }
}

class CreationStudioScreen extends StatelessWidget {
  const CreationStudioScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Creation Studio", style: TextStyle(fontSize: 18.sp)), backgroundColor: AppColors.background),
      body: Center(
        child: Text("Creation Studio Bar:\nBatch Count (1-4) • Seed Lock (🔒) • 2K/4K • Aspect Ratio", textAlign: TextAlign.center, style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary)),
      ),
    );
  }
}

class CloudLibraryScreen extends StatelessWidget {
  const CloudLibraryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cloud Library", style: TextStyle(fontSize: 18.sp)), backgroundColor: AppColors.background),
      body: Center(
        child: Text("Unlimited Cloud Library\nPay-to-Download 4K Master (Flat 2 Credits)", textAlign: TextAlign.center, style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary)),
      ),
    );
  }
}

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Credit Wallet", style: TextStyle(fontSize: 18.sp)), backgroundColor: AppColors.background),
      body: Center(
        child: Text("Dual-Balance Ledger\nPurchased: 120 Cr | Royalties: 45.6 Cr", textAlign: TextAlign.center, style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary)),
      ),
    );
  }
}
