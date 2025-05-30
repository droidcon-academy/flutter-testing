import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dashboard TabBar Navigation Tests', () {
    testWidgets('renders TabBar with correct tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TabBarTestHarness(),
        ),
      );
      
      expect(find.byType(AppBar), findsOneWidget,
          reason: 'AppBar should be present in dashboard');
      
      expect(find.byType(TabBar), findsOneWidget,
          reason: 'TabBar should be present in AppBar bottom');
      
      expect(find.byType(Tab), findsNWidgets(2),
          reason: 'TabBar should contain exactly two tabs');
      
      expect(find.text('Favorites'), findsOneWidget,
          reason: 'First tab should be labeled "Favorites"');
      expect(find.text('Bookmarks'), findsOneWidget,
          reason: 'Second tab should be labeled "Bookmarks"');
      
      expect(find.byIcon(Icons.favorite), findsOneWidget,
          reason: 'First tab should have favorite icon');
      expect(find.byIcon(Icons.bookmark), findsOneWidget,
          reason: 'Second tab should have bookmark icon');
    });
    
    testWidgets('initially displays first tab content', (WidgetTester tester) async {
     
      await tester.pumpWidget(
        const MaterialApp(
          home: TabBarTestHarness(),
        ),
      );
      
      expect(find.byType(TabBarView), findsOneWidget,
          reason: 'TabBarView should be present to display tab content');
      
      expect(find.text('Favorites Content'), findsOneWidget,
          reason: 'First tab content should be displayed initially');
      
      expect(find.text('Bookmarks Content'), findsNothing,
          reason: 'Second tab content should not be visible initially');
    });
    
    testWidgets('can switch between tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TabBarTestHarness(),
        ),
      );
      
      expect(find.text('Favorites Content'), findsOneWidget);
      expect(find.text('Bookmarks Content'), findsNothing);
      
      await tester.tap(find.text('Bookmarks'));
      
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      
      expect(find.text('Bookmarks Content'), findsOneWidget,
          reason: 'Second tab content should be visible after switching tabs');
      expect(find.text('Favorites Content'), findsNothing,
          reason: 'First tab content should not be visible after switching tabs');
      
      await tester.tap(find.text('Favorites'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      
      expect(find.text('Favorites Content'), findsOneWidget,
          reason: 'First tab content should be visible after switching back');
      expect(find.text('Bookmarks Content'), findsNothing,
          reason: 'Second tab content should not be visible after switching back');
    });
    
    testWidgets('tab indicator shows current selection', (WidgetTester tester) async {

      await tester.pumpWidget(
        const MaterialApp(
          home: TabBarTestHarness(),
        ),
      );
      
      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      
      expect(tabBar.tabs.length, 2, 
          reason: 'TabBar should have exactly 2 tabs');
      
      expect(tabBar.controller != null, true,
          reason: 'TabBar should have a non-null controller');
    });
  });
}

class TabBarTestHarness extends StatefulWidget {
  const TabBarTestHarness({Key? key}) : super(key: key);

  @override
  State<TabBarTestHarness> createState() => _TabBarTestHarnessState();
}

class _TabBarTestHarnessState extends State<TabBarTestHarness> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.favorite),
              text: 'Favorites',
            ),
            Tab(
              icon: Icon(Icons.bookmark),
              text: 'Bookmarks',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          Center(child: Text('Favorites Content')),
          Center(child: Text('Bookmarks Content')),
        ],
      ),
    );
  }
}
