// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipevault/core/constants/app_constants.dart';
import 'package:recipevault/presentation/viewmodels/navigation_viewmodel.dart';
import 'package:recipevault/presentation/widgets/common/layout/responsive_layout_builder.dart';

void main() {
  group('Dashboard Navigation State Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('currentPageIndexProvider initializes with index 0', () {
      final pageIndex = container.read(currentPageIndexProvider);
      expect(pageIndex, 0, reason: 'Current page index should initialize to 0');
    });

    test('currentPageIndexProvider.state updates when changed', () {
      expect(container.read(currentPageIndexProvider), 0);
      
      container.read(currentPageIndexProvider.notifier).state = 1;
      
      expect(container.read(currentPageIndexProvider), 1, 
          reason: 'Current page index should be updated to 1');
    });
    
    test('navigationProvider initializes with selectedIndex 0', () {
      final navigationState = container.read(navigationProvider);
      expect(navigationState.selectedIndex, 0, 
          reason: 'Navigation state selectedIndex should initialize to 0');
    });
    
    test('navigationProvider.setSelectedIndex updates state', () {
      expect(container.read(navigationProvider).selectedIndex, 0);
      
      container.read(navigationProvider.notifier).setSelectedIndex(1);
      
      expect(container.read(navigationProvider).selectedIndex, 1, 
          reason: 'selectedIndex should be updated to 1');
    });
  });

  group('Dashboard Navigation UI State Integration Tests', () {
    Widget createNavigationStateTestHarness({int initialIndex = 0}) {
      return ProviderScope(
        overrides: [
          currentPageIndexProvider.overrideWith((_) => initialIndex),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                final pageIndex = ref.watch(currentPageIndexProvider);
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Current Page Index: $pageIndex'),
                      const SizedBox(height: Sizes.spacing),
                      ElevatedButton(
                        onPressed: () => ref.read(currentPageIndexProvider.notifier).state = 1,
                        child: const Text('Navigate to Index 1'),
                      ),
                      ElevatedButton(
                        onPressed: () => ref.read(currentPageIndexProvider.notifier).state = 2,
                        child: const Text('Navigate to Index 2'),
                      ),
                      ElevatedButton(
                        onPressed: () => ref.read(currentPageIndexProvider.notifier).state = 0,
                        child: const Text('Back to Index 0'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    testWidgets('UI updates when page index changes', (WidgetTester tester) async {
      await tester.pumpWidget(createNavigationStateTestHarness());
      
      expect(find.text('Current Page Index: 0'), findsOneWidget);
      
      await tester.tap(find.text('Navigate to Index 1'));
      await tester.pump();

      expect(find.text('Current Page Index: 1'), findsOneWidget);
      expect(find.text('Current Page Index: 0'), findsNothing);
      
      await tester.tap(find.text('Navigate to Index 2'));
      await tester.pump();
      
      expect(find.text('Current Page Index: 2'), findsOneWidget);
      expect(find.text('Current Page Index: 1'), findsNothing);
      
      await tester.tap(find.text('Back to Index 0'));
      await tester.pump();

      expect(find.text('Current Page Index: 0'), findsOneWidget);
      expect(find.text('Current Page Index: 2'), findsNothing);
    });

    testWidgets('Widget displays correct content based on initial page index', 
        (WidgetTester tester) async {
      await tester.pumpWidget(createNavigationStateTestHarness(initialIndex: 1));
      
      expect(find.text('Current Page Index: 1'), findsOneWidget);
      expect(find.text('Current Page Index: 0'), findsNothing);
    });
  });

  group('Dashboard Navigation Integration Tests', () {
    Widget createDashboardNavigationWidget() {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                final pageIndex = ref.watch(currentPageIndexProvider);
                
                return ResponsiveLayoutBuilder(
                  mobile: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            icon: Icon(
                              pageIndex == 0 ? Icons.home : Icons.home_outlined,
                              color: pageIndex == 0 ? Colors.blue : Colors.grey,
                            ),
                            onPressed: () => ref.read(currentPageIndexProvider.notifier).state = 0,
                          ),
                          IconButton(
                            icon: Icon(
                              pageIndex == 1 ? Icons.favorite : Icons.favorite_outline,
                              color: pageIndex == 1 ? Colors.blue : Colors.grey,
                            ),
                            onPressed: () => ref.read(currentPageIndexProvider.notifier).state = 1,
                          ),
                          IconButton(
                            icon: Icon(
                              pageIndex == 2 ? Icons.bookmark : Icons.bookmark_outline,
                              color: pageIndex == 2 ? Colors.blue : Colors.grey,
                            ),
                            onPressed: () => ref.read(currentPageIndexProvider.notifier).state = 2,
                          ),
                        ],
                      ),
                      Expanded(
                        child: IndexedStack(
                          index: pageIndex,
                          children: const [
                            Center(child: Text('Home Screen')),
                            Center(child: Text('Favorites Screen')),
                            Center(child: Text('Bookmarks Screen')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  tablet: Row(
                    children: [
                      Container(
                        width: 200,
                        color: Colors.grey[200],
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                pageIndex == 0 ? Icons.home : Icons.home_outlined,
                                color: pageIndex == 0 ? Colors.blue : Colors.grey,
                              ),
                              title: const Text('Home'),
                              selected: pageIndex == 0,
                              onTap: () => ref.read(currentPageIndexProvider.notifier).state = 0,
                            ),
                            ListTile(
                              leading: Icon(
                                pageIndex == 1 ? Icons.favorite : Icons.favorite_outline,
                                color: pageIndex == 1 ? Colors.blue : Colors.grey,
                              ),
                              title: const Text('Favorites'),
                              selected: pageIndex == 1,
                              onTap: () => ref.read(currentPageIndexProvider.notifier).state = 1,
                            ),
                            ListTile(
                              leading: Icon(
                                pageIndex == 2 ? Icons.bookmark : Icons.bookmark_outline,
                                color: pageIndex == 2 ? Colors.blue : Colors.grey,
                              ),
                              title: const Text('Bookmarks'),
                              selected: pageIndex == 2,
                              onTap: () => ref.read(currentPageIndexProvider.notifier).state = 2,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: IndexedStack(
                          index: pageIndex,
                          children: const [
                            Center(child: Text('Home Screen')),
                            Center(child: Text('Favorites Screen')),
                            Center(child: Text('Bookmarks Screen')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  desktopWeb: Row(
                    children: [
                      Container(
                        width: 250,
                        color: Colors.grey[200],
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                pageIndex == 0 ? Icons.home : Icons.home_outlined,
                                color: pageIndex == 0 ? Colors.blue : Colors.grey,
                              ),
                              title: const Text('Home'),
                              selected: pageIndex == 0,
                              onTap: () => ref.read(currentPageIndexProvider.notifier).state = 0,
                            ),
                            ListTile(
                              leading: Icon(
                                pageIndex == 1 ? Icons.favorite : Icons.favorite_outline,
                                color: pageIndex == 1 ? Colors.blue : Colors.grey,
                              ),
                              title: const Text('Favorites'),
                              selected: pageIndex == 1,
                              onTap: () => ref.read(currentPageIndexProvider.notifier).state = 1,
                            ),
                            ListTile(
                              leading: Icon(
                                pageIndex == 2 ? Icons.bookmark : Icons.bookmark_outline,
                                color: pageIndex == 2 ? Colors.blue : Colors.grey,
                              ),
                              title: const Text('Bookmarks'),
                              selected: pageIndex == 2,
                              onTap: () => ref.read(currentPageIndexProvider.notifier).state = 2,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: IndexedStack(
                          index: pageIndex,
                          children: const [
                            Center(child: Text('Home Screen')),
                            Center(child: Text('Favorites Screen')),
                            Center(child: Text('Bookmarks Screen')),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    testWidgets('mobile navigation shows correct content when index changes', 
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(360 * 3, 640 * 3);
      tester.binding.window.devicePixelRatioTestValue = 3.0;
      
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      
      await tester.pumpWidget(createDashboardNavigationWidget());
      
      expect(find.text('Home Screen'), findsOneWidget);
      expect(find.text('Favorites Screen'), findsNothing);
      expect(find.text('Bookmarks Screen'), findsNothing);
      
      final homeIcon = tester.widget<Icon>(find.byIcon(Icons.home));
      expect(homeIcon.color, Colors.blue);
      
      await tester.tap(find.byIcon(Icons.favorite_outline));
      await tester.pump();

      expect(find.text('Home Screen'), findsNothing);
      expect(find.text('Favorites Screen'), findsOneWidget);
      expect(find.text('Bookmarks Screen'), findsNothing);
      
      final favoritesIcon = tester.widget<Icon>(find.byIcon(Icons.favorite));
      expect(favoritesIcon.color, Colors.blue);
      
      await tester.tap(find.byIcon(Icons.bookmark_outline));
      await tester.pump();
      
      expect(find.text('Home Screen'), findsNothing);
      expect(find.text('Favorites Screen'), findsNothing);
      expect(find.text('Bookmarks Screen'), findsOneWidget);
      
      final bookmarksIcon = tester.widget<Icon>(find.byIcon(Icons.bookmark));
      expect(bookmarksIcon.color, Colors.blue);
    });

    testWidgets('tablet navigation shows correct content when index changes', 
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(800 * 2, 1200 * 2);
      tester.binding.window.devicePixelRatioTestValue = 2.0;
      
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      
      await tester.pumpWidget(createDashboardNavigationWidget());
      
      expect(find.text('Home Screen'), findsOneWidget);
      expect(find.text('Favorites Screen'), findsNothing);
      expect(find.text('Bookmarks Screen'), findsNothing);
      
      final homeTile = find.widgetWithText(ListTile, 'Home');
      expect(tester.widget<ListTile>(homeTile).selected, true);
      
      await tester.tap(find.widgetWithText(ListTile, 'Favorites'));
      await tester.pump();

      expect(find.text('Home Screen'), findsNothing);
      expect(find.text('Favorites Screen'), findsOneWidget);
      expect(find.text('Bookmarks Screen'), findsNothing);
      
      final favoritesTile = find.widgetWithText(ListTile, 'Favorites');
      expect(tester.widget<ListTile>(favoritesTile).selected, true);
      
      await tester.tap(find.widgetWithText(ListTile, 'Bookmarks'));
      await tester.pump();
      
      expect(find.text('Home Screen'), findsNothing);
      expect(find.text('Favorites Screen'), findsNothing);
      expect(find.text('Bookmarks Screen'), findsOneWidget);
      
      final bookmarksTile = find.widgetWithText(ListTile, 'Bookmarks');
      expect(tester.widget<ListTile>(bookmarksTile).selected, true);
    });
  });
}
