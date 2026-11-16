import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:craftai_studio_mobile/shared/widgets/image/zoomable_image_lightbox.dart';

Widget wrapWithScreenUtil(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (context, _) => MaterialApp(
      home: Scaffold(
        body: child,
      ),
    ),
  );
}

void main() {
  group('ZoomableImageLightbox Widget Tests', () {
    testWidgets('renders InteractiveViewer, controls overlay, and titles', (tester) async {
      await tester.pumpWidget(
        wrapWithScreenUtil(
          const ZoomableImageLightbox(
            imageUrl: 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f',
            title: 'Majestic Lion',
            subtitle: 'FLUX.1 Schnell',
            aspectRatioStr: '16:9',
          ),
        ),
      );
      await tester.pump();

      // Check InteractiveViewer
      expect(find.byType(InteractiveViewer), findsOneWidget);

      final interactiveViewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      expect(interactiveViewer.minScale, 1.0);
      expect(interactiveViewer.maxScale, 5.0);

      // Check header info
      expect(find.text('Majestic Lion'), findsOneWidget);
      expect(find.text('FLUX.1 Schnell'), findsOneWidget);
      expect(find.text('16:9'), findsOneWidget);

      // Check close button
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Check initial zoom prompt
      expect(find.text('Pinch or Double-Tap to Zoom'), findsOneWidget);
    });

    testWidgets('single tap toggles visibility of controls overlay', (tester) async {
      await tester.pumpWidget(
        wrapWithScreenUtil(
          const ZoomableImageLightbox(
            imageUrl: 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f',
            title: 'Cyber Ronin',
          ),
        ),
      );
      await tester.pump();

      // Initially controls are shown
      expect(find.text('Cyber Ronin'), findsOneWidget);

      // Tap on image area to toggle controls off
      await tester.tap(find.byType(InteractiveViewer));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // AnimatedOpacity for controls will be 0.0
      final opacities = tester.widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity));
      for (final opacity in opacities) {
        expect(opacity.opacity, 0.0);
      }

      // Tap again to toggle back on
      await tester.tap(find.byType(InteractiveViewer));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final opacitiesAfter = tester.widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity));
      for (final opacity in opacitiesAfter) {
        expect(opacity.opacity, 1.0);
      }
    });

    testWidgets('double-tap zooms in and displays Reset action pill', (tester) async {
      await tester.pumpWidget(
        wrapWithScreenUtil(
          const ZoomableImageLightbox(
            imageUrl: 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f',
            title: 'Landscape Art',
          ),
        ),
      );
      await tester.pump();

      // Double tap center of InteractiveViewer
      await tester.tap(find.byType(InteractiveViewer));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(InteractiveViewer));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Reset button should now be visible
      expect(find.text('Reset'), findsOneWidget);
      expect(find.textContaining('Zoom'), findsOneWidget);

      // Tap Reset button
      await tester.tap(find.text('Reset'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Returns to initial hint
      expect(find.text('Pinch or Double-Tap to Zoom'), findsOneWidget);
      expect(find.text('Reset'), findsNothing);
    });

    testWidgets('ZoomableImageLightbox.show static helper pushes and pops route cleanly', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, _) => MaterialApp(
            home: Builder(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    ZoomableImageLightbox.show(
                      context: ctx,
                      imageUrl: 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f',
                      title: 'Modal Test',
                    );
                  },
                  child: const Text('Open Lightbox'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap button to open lightbox
      await tester.tap(find.text('Open Lightbox'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ZoomableImageLightbox), findsOneWidget);
      expect(find.text('Modal Test'), findsOneWidget);

      // Tap close icon to pop
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ZoomableImageLightbox), findsNothing);
    });
  });
}

