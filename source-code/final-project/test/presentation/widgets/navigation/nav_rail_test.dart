import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/core/constants/app_constants.dart';
import 'package:recipevault/presentation/widgets/navigation/nav_rail.dart';

void main() {
  group('NavRail Widget Tests', () {
    Widget createNavRailTestHarness({
      required int selectedIndex,
      required Function(int) onDestinationSelected,
    }) {
      return MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: Scaffold(
          body: ProviderScope(
            child: Row(
              children: [
                NavRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                ),
                const Expanded(child: Placeholder()), 
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('renders navigation rail with correct destinations', (WidgetTester tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        createNavRailTestHarness(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            selectedIndex = index;
          },
        ),
      );

      expect(find.byType(NavigationRail), findsOneWidget,
          reason: 'NavigationRail should be present');

      expect(find.text('Recipe'), findsOneWidget,
          reason: 'Recipe destination should be present');
      expect(find.text('Dashboard'), findsOneWidget,
          reason: 'Dashboard destination should be present');

      expect(find.byIcon(Icons.menu_book), findsOneWidget,
          reason: 'Recipe icon should be present');
      expect(find.byIcon(Icons.dashboard), findsOneWidget,
          reason: 'Dashboard icon should be present');
      
      expect(find.byIcon(Icons.flutter_dash), findsOneWidget,
          reason: 'Leading Flutter Dash icon should be present');
    });

    testWidgets('highlights the selected destination', (WidgetTester tester) async {

      int selectedIndex = 0;

      await tester.pumpWidget(
        createNavRailTestHarness(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            selectedIndex = index;
          },
        ),
      );

      final navigationRail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(navigationRail.selectedIndex, equals(0),
          reason: 'NavigationRail should have index 0 (Recipe) selected');

      await tester.pumpWidget(
        createNavRailTestHarness(
          selectedIndex: 1,
          onDestinationSelected: (index) {
            selectedIndex = index;
          },
        ),
      );

      final updatedNavigationRail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(updatedNavigationRail.selectedIndex, equals(1),
          reason: 'NavigationRail should have index 1 (Dashboard) selected');
    });

    testWidgets('calls callback when destination is tapped', (WidgetTester tester) async {
      int selectedIndex = 0;
      bool callbackCalled = false;

      await tester.pumpWidget(
        createNavRailTestHarness(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            selectedIndex = index;
            callbackCalled = true;
          },
        ),
      );

      expect(selectedIndex, equals(0),
          reason: 'Initial selected index should be 0 (Recipe)');
      expect(callbackCalled, isFalse,
          reason: 'Callback should not have been called yet');

      await tester.tap(find.text('Dashboard'));
      await tester.pump();

      expect(callbackCalled, isTrue,
          reason: 'Callback should be called when destination is tapped');
      expect(selectedIndex, equals(1),
          reason: 'Selected index should be updated to 1 (Dashboard)');
    });

    testWidgets('has correct theme and appearance', (WidgetTester tester) async {
      await tester.pumpWidget(
        createNavRailTestHarness(
          selectedIndex: 0,
          onDestinationSelected: (index) {},
        ),
      );

      final navigationRail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      
      expect(navigationRail.useIndicator, isTrue,
          reason: 'NavigationRail should use indicator');
      
      expect(navigationRail.indicatorColor, isNotNull,
          reason: 'NavigationRail should have an indicator color');
      
      expect(navigationRail.backgroundColor, isNotNull,
          reason: 'NavigationRail should have a background color');
      
      final leadingIcon = find.descendant(
        of: find.byType(NavigationRail),
        matching: find.byIcon(Icons.flutter_dash),
      );
      expect(leadingIcon, findsOneWidget, reason: 'Flutter Dash icon should be present as leading widget');
      
      final icon = tester.widget<Icon>(find.byIcon(Icons.flutter_dash));
      expect(icon.size, equals(Sizes.iconMedium),
          reason: 'Flutter dash icon should have correct size');
    });

    testWidgets('navigation rail is accessible', (WidgetTester tester) async {
      await tester.pumpWidget(
        createNavRailTestHarness(
          selectedIndex: 0,
          onDestinationSelected: (index) {},
        ),
      );

      final recipeDestination = find.text('Recipe');
      final dashboardDestination = find.text('Dashboard');
      
      expect(recipeDestination, findsOneWidget,
          reason: 'Recipe destination should be present');
      expect(dashboardDestination, findsOneWidget,
          reason: 'Dashboard destination should be present');
      
      final navRail = find.byType(NavigationRail);
      expect(navRail, findsOneWidget, reason: 'NavigationRail should be present');
      
      final navRailWidget = tester.widget<NavRail>(find.byType(NavRail));
      navRailWidget.onDestinationSelected(0); 
      navRailWidget.onDestinationSelected(1);
      
      await tester.pump();
      
      final recipeSemantics = tester.getSemantics(recipeDestination);
      expect(recipeSemantics.label, isNotNull,
          reason: 'Recipe destination should have an accessibility label');
      expect(recipeSemantics.label, contains('Recipe'),
          reason: 'Recipe destination label should contain "Recipe"');
      
      final dashboardSemantics = tester.getSemantics(dashboardDestination);
      expect(dashboardSemantics.label, isNotNull,
          reason: 'Dashboard destination should have an accessibility label');
      expect(dashboardSemantics.label, contains('Dashboard'),
          reason: 'Dashboard destination label should contain "Dashboard"');
    });
  });
}