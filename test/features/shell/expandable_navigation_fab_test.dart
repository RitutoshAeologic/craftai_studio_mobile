import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:craftai_studio_mobile/features/shell/widgets/expandable_navigation_fab.dart';

void main() {
  Widget wrapWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              const Center(child: Text('Background Content')),
              child,
            ],
          ),
        ),
      ),
    );
  }

  group('ExpandableNavigationFab Unit and Widget Tests', () {
    testWidgets('renders trigger button and remains collapsed initially', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fabKey = GlobalKey<ExpandableNavigationFabState>();
      bool itemTapped = false;

      await tester.pumpWidget(
        wrapWidget(
          ExpandableNavigationFab(
            key: fabKey,
            items: [
              FabMenuItem(
                title: 'Creation Studio',
                subtitle: 'Generate AI art',
                icon: Icons.auto_awesome,
                accentColor: Colors.purple,
                onTap: () => itemTapped = true,
              ),
              FabMenuItem(
                title: 'AI Tools Hub',
                subtitle: 'All AI tools',
                icon: Icons.handyman,
                accentColor: Colors.blue,
                onTap: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(fabKey.currentState?.isExpanded, isFalse);
      expect(find.byKey(const ValueKey('expandable_nav_fab_trigger')), findsOneWidget);
      expect(find.text('Creation Studio'), findsNothing);
      expect(find.text('AI Tools Hub'), findsNothing);

      // Tap trigger to expand
      await tester.tap(find.byKey(const ValueKey('expandable_nav_fab_trigger')));
      await tester.pumpAndSettle();

      expect(fabKey.currentState?.isExpanded, isTrue);
      expect(find.text('Creation Studio'), findsOneWidget);
      expect(find.text('AI Tools Hub'), findsOneWidget);

      // Tap menu item
      await tester.tap(find.byKey(const ValueKey('fab_item_Creation Studio')));
      await tester.pumpAndSettle();

      expect(itemTapped, isTrue);
      expect(fabKey.currentState?.isExpanded, isFalse);
      expect(find.text('Creation Studio'), findsNothing);
    });

    testWidgets('tapping barrier collapses expanded menu', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fabKey = GlobalKey<ExpandableNavigationFabState>();

      await tester.pumpWidget(
        wrapWidget(
          ExpandableNavigationFab(
            key: fabKey,
            items: [
              FabMenuItem(
                title: 'Test Tool',
                subtitle: 'Description',
                icon: Icons.star,
                accentColor: Colors.amber,
                onTap: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expand
      await tester.tap(find.byKey(const ValueKey('expandable_nav_fab_trigger')));
      await tester.pumpAndSettle();
      expect(fabKey.currentState?.isExpanded, isTrue);
      expect(find.text('Test Tool'), findsOneWidget);

      // Tap at top of screen (barrier)
      await tester.tapAt(const Offset(100, 100));
      await tester.pumpAndSettle();

      expect(fabKey.currentState?.isExpanded, isFalse);
      expect(find.text('Test Tool'), findsNothing);
    });

    testWidgets('collapse() method collapses menu programmatically', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fabKey = GlobalKey<ExpandableNavigationFabState>();

      await tester.pumpWidget(
        wrapWidget(
          ExpandableNavigationFab(
            key: fabKey,
            items: [
              FabMenuItem(
                title: 'Quick Tool',
                subtitle: 'Sub',
                icon: Icons.bolt,
                accentColor: Colors.teal,
                onTap: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      fabKey.currentState?.toggle();
      await tester.pumpAndSettle();
      expect(fabKey.currentState?.isExpanded, isTrue);

      fabKey.currentState?.collapse();
      await tester.pumpAndSettle();
      expect(fabKey.currentState?.isExpanded, isFalse);
    });
  });
}
