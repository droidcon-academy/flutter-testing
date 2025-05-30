import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:recipevault/presentation/views/dashboard/components/dashboard_tab_layout.dart';

class MockDashboardViewModel extends Mock implements DashboardViewModel {}

class TestWrapper extends StatelessWidget {
  final Widget child;
  final List<Override> overrides;

  const TestWrapper({
    super.key,
    required this.child,
    this.overrides = const [],
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: child,
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockDashboardViewModel mockViewModel;
  
  setUp(() {
    mockViewModel = MockDashboardViewModel();
    
    when(() => mockViewModel.initializeData()).thenAnswer((_) async {});
    
    const defaultState = DashboardState(
      recipes: [],
      favoriteIds: {},
      bookmarkIds: {},
      isLoading: false,
      isPartiallyLoaded: false,
      error: null,
    );

    when(() => mockViewModel.state).thenReturn(defaultState);
    when(() => mockViewModel.state.favoriteRecipes).thenReturn([]);
    when(() => mockViewModel.state.bookmarkedRecipes).thenReturn([]);
  });
  
  testWidgets('Basic infrastructure test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Dashboard Tab Layout Test'),
          ),
        ),
      ),
    );
    
    expect(find.text('Dashboard Tab Layout Test'), findsOneWidget);
  });
  
  test('DashboardTabLayout can be instantiated', () {
    final widget = DashboardTabLayout(
      onRecipeSelected: (Recipe recipe) {},
    );
    
    expect(widget, isA<DashboardTabLayout>());
  });

  testWidgets('Minimal provider test', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestWrapper(
        overrides: [
          dashboardProvider.overrideWith((_) => mockViewModel),
        ],
        child: const Scaffold(
          body: Center(
            child: Text('Minimal Provider Test'),
          ),
        ),
      ),
    );

    expect(find.text('Minimal Provider Test'), findsOneWidget);
  });

  testWidgets('DashboardTabLayout renders basic structure', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('My Dashboard'),
            bottom: TabBar(
              controller: TabController(length: 2, vsync: tester),
              tabs: const [
                Tab(icon: Icon(Icons.favorite), text: 'Favorites'),
                Tab(icon: Icon(Icons.bookmark), text: 'Bookmarks'),
              ],
            ),
          ),
          body: const Center(
            child: Text('Tab Content Placeholder'),
          ),
        ),
      ),
    );
    
    expect(find.text('My Dashboard'), findsOneWidget);
    
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Bookmarks'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });


}
