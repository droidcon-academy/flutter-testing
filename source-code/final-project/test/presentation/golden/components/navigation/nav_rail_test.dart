import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:recipevault/core/themes/app_theme.dart';
import 'package:recipevault/presentation/widgets/navigation/nav_rail.dart';
import 'package:recipevault/presentation/widgets/navigation/bottom_nav_bar.dart';
import 'package:recipevault/presentation/widgets/common/layout/responsive_layout_builder.dart';

void main() {
  group('Navigation Rail Golden Tests (Implementation-Aware)', () {
    setUpAll(() async {
      await loadAppFonts();
    });

    testGoldens(
        'NavRail/Navigation - ResponsiveLayoutBuilder (mobile/tablet/desktop)',
        (tester) async {
      int selectedIndex = 1;
      final widget = MaterialApp(
        theme: AppTheme.lightTheme,
        home: ProviderScope(
          child: NavigationHarness(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {},
          ),
        ),
      );

      tester.view.physicalSize = const Size(375, 800);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      expect(find.byType(NavBar), findsOneWidget);
      expect(find.byType(NavRail), findsNothing);
      await screenMatchesGolden(tester, 'nav_rail_responsive_mobile');

      tester.view.physicalSize = const Size(900, 1200);
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      expect(find.byType(NavBar), findsOneWidget);
      expect(find.byType(NavRail), findsNothing);
      await screenMatchesGolden(tester, 'nav_rail_responsive_tablet');

      tester.view.physicalSize = const Size(1400, 900);
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      expect(find.byType(NavBar), findsNothing);
      expect(find.byType(NavRail), findsOneWidget);
      await screenMatchesGolden(tester, 'nav_rail_responsive_desktop');

      addTearDown(tester.view.resetPhysicalSize);
    });

    testGoldens('NavRail - Isolated visual regression', (tester) async {
      final widget = MaterialApp(
        theme: AppTheme.lightTheme,
        home: ProviderScope(
          child: Container(
            color: Colors.white,
            child: NavRail(
              selectedIndex: 1,
              onDestinationSelected: (index) {},
            ),
          ),
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      await multiScreenGolden(
        tester,
        'nav_rail_isolated',
        devices: [const Device(size: Size(200, 400), name: 'rail_only')],
      );
    });

  });
}

class NavigationHarness extends ConsumerWidget {
  final int selectedIndex;
  final void Function(int) onDestinationSelected;
  const NavigationHarness({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveLayoutBuilder(
      mobile: Scaffold(
        appBar: AppBar(title: const Text('Mobile')),
        body: const Center(child: Text('Mobile Content')),
        bottomNavigationBar: NavBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
        ),
      ),
      tablet: Scaffold(
        appBar: AppBar(title: const Text('Tablet')),
        body: const Center(child: Text('Tablet Content')),
        bottomNavigationBar: NavBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
        ),
      ),
      desktopWeb: Scaffold(
        appBar: AppBar(title: const Text('Desktop')),
        body: Row(
          children: [
            NavRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
            ),
            const Expanded(child: Center(child: Text('Desktop Content'))),
          ],
        ),
      ),
    );
  }
}
