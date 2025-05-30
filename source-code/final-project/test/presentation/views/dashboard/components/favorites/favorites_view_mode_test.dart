import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/presentation/views/dashboard/components/favorites/favorite_grid_view.dart';
import 'package:recipevault/presentation/views/dashboard/components/favorites/favorite_list_view.dart';

void main() {
  final testRecipes = [
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

  group('FavoritesView View Mode Tests', () {
    testWidgets('initially displays list view by default', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FavoritesViewTestHarness(
            favoriteRecipes: testRecipes,
          ),
        ),
      );

      expect(find.byType(FavoriteListView), findsOneWidget,
          reason: 'List view should be displayed initially');
      expect(find.byType(FavoriteGridView), findsNothing, 
          reason: 'Grid view should not be displayed initially');
      
      expect(find.byIcon(Icons.grid_view), findsOneWidget,
          reason: 'Grid view icon should be shown when in list view mode');
      expect(find.byIcon(Icons.view_list), findsNothing,
          reason: 'List view icon should not be shown when in list view mode');
    });
    
    testWidgets('tapping toggle button switches to grid view', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FavoritesViewTestHarness(
            favoriteRecipes: testRecipes,
          ),
        ),
      );
      
      expect(find.byType(FavoriteListView), findsOneWidget);
      expect(find.byType(FavoriteGridView), findsNothing);
      
      await tester.tap(find.byIcon(Icons.grid_view));
      await tester.pumpAndSettle(); 

      expect(find.byType(FavoriteListView), findsNothing,
          reason: 'List view should no longer be displayed after toggle');
      expect(find.byType(FavoriteGridView), findsOneWidget,
          reason: 'Grid view should be displayed after toggle');
      
      expect(find.byIcon(Icons.grid_view), findsNothing,
          reason: 'Grid view icon should not be shown when in grid view mode');
      expect(find.byIcon(Icons.view_list), findsOneWidget,
          reason: 'List view icon should be shown when in grid view mode');
    });
    
    testWidgets('can toggle back to list view from grid view', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FavoritesViewTestHarness(
            favoriteRecipes: testRecipes,
            initialGridView: true,
          ),
        ),
      );
      
      expect(find.byType(FavoriteListView), findsNothing);
      expect(find.byType(FavoriteGridView), findsOneWidget);
      expect(find.byIcon(Icons.view_list), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.view_list));
      await tester.pumpAndSettle();
      
      expect(find.byType(FavoriteListView), findsOneWidget,
          reason: 'List view should be displayed after toggling back');
      expect(find.byType(FavoriteGridView), findsNothing,
          reason: 'Grid view should no longer be displayed after toggling back');
      
      expect(find.byIcon(Icons.grid_view), findsOneWidget);
      expect(find.byIcon(Icons.view_list), findsNothing);
    });
  });
}

class FavoritesViewTestHarness extends StatefulWidget {
  final List<Recipe> favoriteRecipes;
  final bool initialGridView;
  
  const FavoritesViewTestHarness({
    Key? key,
    required this.favoriteRecipes,
    this.initialGridView = false,
  }) : super(key: key);
  
  @override
  _FavoritesViewTestHarnessState createState() => _FavoritesViewTestHarnessState();
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
      body: widget.favoriteRecipes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No favorite recipes yet'),
                  SizedBox(height: 16),
                  Text('Add recipes to your favorites to see them here'),
                ],
              ),
            )
          : _showGridView
              ? FavoriteGridView(
                  recipes: widget.favoriteRecipes,
                  onRecipeSelected: (_) {},
                  storageKey: 'favorites_grid',
                  scrollController: _scrollController,
                )
              : FavoriteListView(
                  recipes: widget.favoriteRecipes,
                  onRecipeSelected: (_) {},
                  storageKey: 'favorites_list',
                  scrollController: _scrollController,
                ),
    );
  }
}
