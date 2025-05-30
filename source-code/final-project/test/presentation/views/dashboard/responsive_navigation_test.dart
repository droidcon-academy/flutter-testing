// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipevault/core/utils/responsive_helper.dart';
import 'package:recipevault/presentation/widgets/common/layout/responsive_layout_builder.dart';

void main() {
  group('Dashboard Responsive Navigation Tests', () {
    Widget createNavigationTestWidget() {
      return const MaterialApp(
        home: Scaffold(
          body: ResponsiveLayoutBuilder(
            mobile: Text('Mobile Navigation - TabBar'),
            tablet: Text('Tablet Navigation - SplitView'),
            desktopWeb: Text('Desktop Navigation - SplitView'),
          ),
        ),
      );
    }
    
    testWidgets('displays TabBar navigation on mobile screens', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(360 * 3, 640 * 3); 
      tester.binding.window.devicePixelRatioTestValue = 3.0;
      
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      
      await tester.pumpWidget(createNavigationTestWidget());
      
      expect(find.text('Mobile Navigation - TabBar'), findsOneWidget);
      expect(find.text('Tablet Navigation - SplitView'), findsNothing);
      expect(find.text('Desktop Navigation - SplitView'), findsNothing);
    });
    
    testWidgets('displays SplitView navigation on tablet screens', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(800 * 2, 1200 * 2); 
      tester.binding.window.devicePixelRatioTestValue = 2.0;
      
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      
      await tester.pumpWidget(createNavigationTestWidget());
      
      expect(find.text('Tablet Navigation - SplitView'), findsOneWidget);
      expect(find.text('Mobile Navigation - TabBar'), findsNothing);
      expect(find.text('Desktop Navigation - SplitView'), findsNothing);
    });
    
    testWidgets('displays SplitView navigation on desktop/web screens', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080); 
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      
      await tester.pumpWidget(createNavigationTestWidget());
      
      expect(find.text('Desktop Navigation - SplitView'), findsOneWidget);
      expect(find.text('Mobile Navigation - TabBar'), findsNothing);
      expect(find.text('Tablet Navigation - SplitView'), findsNothing);
    });
  });
  
  group('Dashboard Responsive Navigation Components Integration Tests', () {
    Widget createDashboardNavigationTestHarness() {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return switch (ResponsiveHelper.deviceType) {
                ResponsiveSizes.mobile => const DashboardNavigationMobileTestHarness(),
                ResponsiveSizes.tablet => const DashboardNavigationTabletTestHarness(),
                ResponsiveSizes.desktopWeb => const DashboardNavigationDesktopTestHarness(),
              };
            },
          ),
        ),
      );
    }
    
    testWidgets('mobile dashboard navigation has TabBar with Favorites and Bookmarks tabs', 
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(360 * 3, 640 * 3);
      tester.binding.window.devicePixelRatioTestValue = 3.0;
      
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      
      await tester.pumpWidget(createDashboardNavigationTestHarness());
      
      expect(find.byType(TabBar), findsOneWidget, 
          reason: 'Mobile layout should contain a TabBar for navigation');
      
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Bookmarks'), findsOneWidget);
      
      expect(find.byType(Row), findsNothing, 
          reason: 'Mobile layout should not contain a Row for split view');
    });
    
    testWidgets('tablet dashboard navigation has SplitView with side navigation', 
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(800 * 2, 1200 * 2);
      tester.binding.window.devicePixelRatioTestValue = 2.0;
      
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      
      await tester.pumpWidget(createDashboardNavigationTestHarness());
      
      expect(find.byType(Row), findsWidgets, 
          reason: 'Tablet layout should contain a Row for split view');
      
      expect(find.text('Navigation Rail'), findsOneWidget, 
          reason: 'Tablet layout should show navigation rail');
      expect(find.text('Content Panel'), findsOneWidget, 
          reason: 'Tablet layout should show content panel');
      
      expect(find.byType(TabBar), findsNothing, 
          reason: 'Tablet layout should not contain a TabBar');
    });
    
    testWidgets('desktop dashboard navigation has SplitView with larger side navigation', 
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      
      await tester.pumpWidget(createDashboardNavigationTestHarness());
      
      expect(find.byType(Row), findsWidgets, 
          reason: 'Desktop layout should contain a Row for split view');
      
      expect(find.text('Navigation Rail'), findsOneWidget, 
          reason: 'Desktop layout should show navigation rail');
      expect(find.text('Content Panel'), findsOneWidget, 
          reason: 'Desktop layout should show content panel');
      
      expect(find.text('Wide Navigation Rail'), findsOneWidget, 
          reason: 'Desktop layout should show a wider navigation rail than tablet');
      
      expect(find.byType(TabBar), findsNothing, 
          reason: 'Desktop layout should not contain a TabBar');
    });
  });
}

class DashboardNavigationMobileTestHarness extends StatefulWidget {
  const DashboardNavigationMobileTestHarness({Key? key}) : super(key: key);

  @override
  State<DashboardNavigationMobileTestHarness> createState() => _DashboardNavigationMobileTestHarnessState();
}

class _DashboardNavigationMobileTestHarnessState extends State<DashboardNavigationMobileTestHarness> 
    with SingleTickerProviderStateMixin {
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
        title: const Text('Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.favorite), text: 'Favorites'),
            Tab(icon: Icon(Icons.bookmark), text: 'Bookmarks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          Center(child: Text('Favorites Tab Content')),
          Center(child: Text('Bookmarks Tab Content')),
        ],
      ),
    );
  }
}

class DashboardNavigationTabletTestHarness extends StatelessWidget {
  const DashboardNavigationTabletTestHarness({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(
          width: 72,
          child: Column(
            children: [
              SizedBox(height: 16),
              Icon(Icons.menu, size: 24),
              SizedBox(height: 8),
              Text('Navigation Rail'),
            ],
          ),
        ),
        VerticalDivider(width: 1),
        Expanded(
          child: Center(
            child: Text('Content Panel'),
          ),
        ),
      ],
    );
  }
}
class DashboardNavigationDesktopTestHarness extends StatelessWidget {
  const DashboardNavigationDesktopTestHarness({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(
          width: 240,
          child: Column(
            children: [
              SizedBox(height: 16),
              Icon(Icons.menu, size: 24),
              SizedBox(height: 8),
              Text('Navigation Rail'),
              SizedBox(height: 8),
              Text('Wide Navigation Rail'),
            ],
          ),
        ),
        VerticalDivider(width: 1),
        Expanded(
          child: Center(
            child: Text('Content Panel'),
          ),
        ),
      ],
    );
  }
}
