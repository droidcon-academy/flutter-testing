import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipevault/core/constants/app_constants.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/presentation/views/dashboard/components/favorites/favorite_grid_view.dart';
import 'package:recipevault/presentation/views/dashboard/components/favorites/favorite_list_view.dart';

void main() {
  late List<Recipe> testRecipes;
  
  setUp(() {
    testRecipes = [
      const Recipe(
        id: '1',
        name: 'Test Recipe 1',
        ingredients: [
          Ingredient(name: 'Ingredient 1', measure: '2 cups'),
          Ingredient(name: 'Ingredient 2', measure: '1 tbsp'),
        ],
        instructions: 'Step 1. Do this. Step 2. Do that.',
        thumbnailUrl: 'test_image_1.jpg',
        isFavorite: true,
      ),
      const Recipe(
        id: '2',
        name: 'Test Recipe 2',
        ingredients: [
          Ingredient(name: 'Ingredient 3', measure: '3 cups'),
          Ingredient(name: 'Ingredient 4', measure: '2 tbsp'),
        ],
        instructions: 'Step 1. Mix ingredients. Step 2. Cook until done.',
        thumbnailUrl: 'test_image_2.jpg',
        isFavorite: true,
      ),
    ];
  });

  group('FavoritesView UI Tests', () {
    testWidgets('displays loading state correctly', (WidgetTester tester) async {
 
      await tester.pumpWidget(
        const MaterialApp(
          home: FavoritesViewTestHarness(
            isLoading: true,
          ),
        ),
      );
      await tester.pump();
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget,
          reason: 'Should show loading indicator when loading');
      expect(find.text('Loading favorites...'), findsOneWidget,
          reason: 'Should show loading message when loading');
    });
    
    testWidgets('displays empty state correctly', (WidgetTester tester) async {

      await tester.pumpWidget(
        const MaterialApp(
          home: FavoritesViewTestHarness(
            favoriteRecipes: [],
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      expect(find.text('No favorite recipes yet'), findsOneWidget,
          reason: 'Should show empty state title');
      expect(find.text('Add recipes to your favorites to see them here'), findsOneWidget,
          reason: 'Should show empty state message');
      expect(find.byIcon(Icons.favorite_border), findsOneWidget,
          reason: 'Should show empty heart icon');
    });
    
    testWidgets('displays recipe content correctly', (WidgetTester tester) async {

      await tester.pumpWidget(
        MaterialApp(
          home: FavoritesViewTestHarness(
            favoriteRecipes: testRecipes,
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      expect(find.byType(FavoriteListView), findsOneWidget,
          reason: 'List view should be displayed initially');
      expect(find.text('Test Recipe 1'), findsOneWidget,
          reason: 'First recipe name should be displayed');
    });
  });
  
  group('FavoritesView Interaction Tests', () {
    testWidgets('toggles between list and grid view', (WidgetTester tester) async {
    
      await tester.pumpWidget(
        MaterialApp(
          home: FavoritesViewTestHarness(
            favoriteRecipes: testRecipes,
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      expect(find.byIcon(Icons.grid_view), findsOneWidget);
      expect(find.byType(FavoriteListView), findsOneWidget);
      expect(find.byType(FavoriteGridView), findsNothing);
      
      await tester.tap(find.byIcon(Icons.grid_view));
      await tester.pumpAndSettle();
      
      expect(find.byIcon(Icons.view_list), findsOneWidget);
      expect(find.byType(FavoriteGridView), findsOneWidget);
      expect(find.byType(FavoriteListView), findsNothing);
    });
  });
}

class FavoritesViewTestHarness extends StatefulWidget {
  final List<Recipe> favoriteRecipes;
  final bool isLoading;
  final ValueChanged<Recipe>? onRecipeSelected;
  final bool initialGridView;
  
  const FavoritesViewTestHarness({
    super.key,
    this.favoriteRecipes = const [],
    this.isLoading = false,
    this.onRecipeSelected,
    this.initialGridView = false,
  });
  
  @override
  State<FavoritesViewTestHarness> createState() => _FavoritesViewTestHarnessState();
}

class _FavoritesViewTestHarnessState extends State<FavoritesViewTestHarness> {
  late bool _showGridView;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _showGridView = widget.initialGridView;
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
   
    if (widget.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favorites')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading favorites...'),
            ],
          ),
        ),
      );
    }
    
    if (widget.favoriteRecipes.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favorites')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No favorite recipes yet'),
              SizedBox(height: 8),
              Text('Add recipes to your favorites to see them here'),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_showGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _showGridView = !_showGridView;
              });
            },
          ),
        ],
      ),
      body: _showGridView
          ? FavoriteGridView(
              recipes: widget.favoriteRecipes,
              onRecipeSelected: widget.onRecipeSelected,
              storageKey: 'favorites_grid',
              scrollController: _scrollController,
            )
          : FavoriteListView(
              recipes: widget.favoriteRecipes,
              onRecipeSelected: widget.onRecipeSelected,
              storageKey: 'favorites_list',
              scrollController: _scrollController,
            ),
    );
  }
}
