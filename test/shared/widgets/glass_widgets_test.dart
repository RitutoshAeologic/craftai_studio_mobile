import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_icons.dart';
import 'package:craftai_studio_mobile/shared/widgets/glass/glass_container.dart';
import 'package:craftai_studio_mobile/shared/widgets/glass/glass_icon_tile.dart';
import 'package:craftai_studio_mobile/shared/widgets/interactions/bouncy_tap.dart';
import 'package:craftai_studio_mobile/shared/widgets/loading/ai_pulse_loader.dart';
import 'package:craftai_studio_mobile/shared/widgets/loading/glass_shimmer_skeleton.dart';
import 'package:craftai_studio_mobile/shared/widgets/glass/modern_ai_button.dart';

Widget wrapWithScreenUtil(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (context, _) => MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    ),
  );
}

void main() {
  group('Glassmorphic Design Toolkit Widget Tests', () {
    testWidgets('GlassContainer renders child with BackdropFilter cleanly', (tester) async {
      await tester.pumpWidget(
        wrapWithScreenUtil(
          const GlassContainer(
            child: Text('Frosted Glass Test'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Frosted Glass Test'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('GlassIconTile renders vector icon without raw emoji', (tester) async {
      await tester.pumpWidget(
        wrapWithScreenUtil(
          const GlassIconTile(
            icon: AppIcons.bgRemover,
            accentColor: AppColors.accentSuccess,
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(AppIcons.bgRemover), findsOneWidget);
    });

    testWidgets('BouncyTap scales down on tap and triggers callback on tap up', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        wrapWithScreenUtil(
          BouncyTap(
            onTap: () {
              tapped = true;
            },
            child: const Text('Tap Me'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Tap Me'), findsOneWidget);

      // Tap down
      final gesture = await tester.startGesture(tester.getCenter(find.text('Tap Me')));
      await tester.pump(const Duration(milliseconds: 50));

      // Release gesture
      await gesture.up();
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('AiPulseLoader renders glowing custom painter and message', (tester) async {
      await tester.pumpWidget(
        wrapWithScreenUtil(
          const AiPulseLoader(
            message: 'Synthesizing pixels...',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Synthesizing pixels...'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('GlassShimmerSkeleton renders with animated gradient', (tester) async {
      await tester.pumpWidget(
        wrapWithScreenUtil(
          const GlassShimmerSkeleton(
            width: 100,
            height: 100,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(GlassShimmerSkeleton), findsOneWidget);
    });

    testWidgets('ModernAiButton renders idle label and triggers onPressed', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        wrapWithScreenUtil(
          ModernAiButton(
            label: 'Generate Artwork',
            onPressed: () {
              pressed = true;
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Generate Artwork'), findsOneWidget);

      await tester.tap(find.text('Generate Artwork'));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });

    testWidgets('ModernAiButton renders loading message when isLoading is true', (tester) async {
      await tester.pumpWidget(
        wrapWithScreenUtil(
          ModernAiButton(
            label: 'Generate Artwork',
            isLoading: true,
            loadingMessage: 'Diffusing scene...',
            onPressed: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Diffusing scene...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    test('AppIcons registry defines non-null IconData for all tools and nav', () {
      expect(AppIcons.bgRemover, isNotNull);
      expect(AppIcons.magicEraser, isNotNull);
      expect(AppIcons.photoColorizer, isNotNull);
      expect(AppIcons.aiBackgrounds, isNotNull);
      expect(AppIcons.aiExpand, isNotNull);
      expect(AppIcons.upscaler, isNotNull);
      expect(AppIcons.navExplore, isNotNull);
      expect(AppIcons.navStudio, isNotNull);
      expect(AppIcons.navTools, isNotNull);
      expect(AppIcons.navLibrary, isNotNull);
      expect(AppIcons.navProfile, isNotNull);
    });
  });
}

