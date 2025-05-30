import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/presentation/widgets/navigation/bottom_nav_bar.dart';

void main() {
  group('NavBar Widget Tests', () {
    Widget createNavBarTestHarness({
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
            child: NavBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
            ),
          ),
        ),
      );
    }

    testWidgets('renders bottom navigation bar with correct destinations', (WidgetTester tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        createNavBarTestHarness(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            selectedIndex = index;
          },
        ),
      );

      expect(find.byType(NavigationBar), findsOneWidget,
          reason: 'NavigationBar should be present');

      expect(find.text('Recipe'), findsOneWidget,
          reason: 'Recipe destination should be present');
      expect(find.text('Dashboard'), findsOneWidget,
          reason: 'Dashboard destination should be present');

      expect(find.byIcon(Icons.menu_book), findsOneWidget,
          reason: 'Recipe icon should be present');
      expect(find.byIcon(Icons.dashboard), findsOneWidget,
          reason: 'Dashboard icon should be present');
    });

    testWidgets('highlights the selected destination', (WidgetTester tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        createNavBarTestHarness(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            selectedIndex = index;
          },
        ),
      );

      final navigationBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navigationBar.selectedIndex, equals(0),
          reason: 'NavigationBar should have index 0 (Recipe) selected');

      await tester.pumpWidget(
        createNavBarTestHarness(
          selectedIndex: 1,
          onDestinationSelected: (index) {
            selectedIndex = index;
          },
        ),
      );

      final updatedNavigationBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(updatedNavigationBar.selectedIndex, equals(1),
          reason: 'NavigationBar should have index 1 (Dashboard) selected');
    });

    testWidgets('calls callback when destination is tapped', (WidgetTester tester) async {
      int selectedIndex = 0;
      bool callbackCalled = false;

      await tester.pumpWidget(
        createNavBarTestHarness(
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
        createNavBarTestHarness(
          selectedIndex: 0,
          onDestinationSelected: (index) {},
        ),
      );

      final navigationBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      
      expect(navigationBar.indicatorColor, isNotNull,
          reason: 'NavigationBar should have an indicator color');
      
      expect(navigationBar.backgroundColor, isNotNull,
          reason: 'NavigationBar should have a background color');
    });

    testWidgets('navigation bar is accessible', (WidgetTester tester) async {
      await tester.pumpWidget(
        createNavBarTestHarness(
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
      
      final navBar = find.byType(NavigationBar);
      expect(navBar, findsOneWidget, reason: 'NavigationBar should be present');
      
      final navBarWidget = tester.widget<NavBar>(find.byType(NavBar));
      navBarWidget.onDestinationSelected(0); 
      navBarWidget.onDestinationSelected(1); 
      
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