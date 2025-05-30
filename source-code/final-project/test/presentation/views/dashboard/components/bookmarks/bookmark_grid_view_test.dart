import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipevault/core/utils/responsive_helper.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/presentation/widgets/recipe/grid/recipe_grid_card.dart';

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
        isBookmarked: true,
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
        isBookmarked: true,
      ),
      const Recipe(
        id: '3',
        name: 'Test Recipe 3',
        ingredients: [
          Ingredient(name: 'Ingredient 5', measure: '1 cup'),
          Ingredient(name: 'Ingredient 6', measure: '3 tbsp'),
        ],
        instructions: 'Step 1. Prepare ingredients. Step 2. Cook thoroughly.',
        thumbnailUrl: 'test_image_3.jpg',
        isBookmarked: true,
      ),
      const Recipe(
        id: '4',
        name: 'Test Recipe 4',
        ingredients: [
          Ingredient(name: 'Ingredient 7', measure: '4 cups'),
          Ingredient(name: 'Ingredient 8', measure: '2 tbsp'),
        ],
        instructions: 'Step 1. Mix well. Step 2. Bake until golden.',
        thumbnailUrl: 'test_image_4.jpg',
        isBookmarked: true,
      ),
    ];
  });

  group('BookmarkGridView UI Tests', () {
    testWidgets('displays recipes in grid format', (WidgetTester tester) async {
     
      await tester.pumpWidget(
        MaterialApp(
          home: BookmarkGridViewTestHarness(
            recipes: testRecipes,
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      expect(find.byType(GridView), findsOneWidget,
          reason: 'Should display recipes in a GridView');
      expect(find.byType(RecipeGridCard), findsNWidgets(4),
          reason: 'Should display 4 RecipeGridCard widgets');
      expect(find.text('Test Recipe 1'), findsOneWidget,
          reason: 'Should display the first recipe name');
      expect(find.text('Test Recipe 4'), findsOneWidget,
          reason: 'Should display the fourth recipe name');
    });
    
    testWidgets('displays empty state when no recipes available', (WidgetTester tester) async {
      
      await tester.pumpWidget(
        const MaterialApp(
          home: BookmarkGridViewTestHarness(
            recipes: [],
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      expect(find.text('No bookmarked recipes yet'), findsOneWidget,
          reason: 'Should show empty state title');
      expect(find.text('Add recipes to your bookmarks to see them here'), findsOneWidget,
          reason: 'Should show empty state message');
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget,
          reason: 'Should show bookmark outline icon');
    });
    
    testWidgets('provides recipe selection callback to grid cards', (WidgetTester tester) async {
     
      bool callbackProvided = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return BookmarkGridViewTestHarness(
                  recipes: testRecipes,
                  onRecipeSelected: (recipe) {
                    callbackProvided = true;
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      final gridCard = tester.widget<RecipeGridCard>(find.byType(RecipeGridCard).first);
      expect(gridCard.onTap != null, isTrue,
          reason: 'RecipeGridCard should have a non-null onTap callback');
      
      gridCard.onTap!();
      expect(callbackProvided, isTrue,
          reason: 'onRecipeSelected callback should be triggered when onTap is called');
    });
  });

  group('BookmarkGridView Responsive Tests', () {
    testWidgets('adapts grid columns based on screen width', (WidgetTester tester) async {
      
      await tester.binding.setSurfaceSize(const Size(320, 600));
      await tester.pumpWidget(
        const MaterialApp(
          home: BookmarkGridViewTestHarness(
            recipes: [],
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      expect(find.text('No bookmarked recipes yet'), findsOneWidget,
          reason: 'Should show empty state title at mobile size');
      
      await tester.binding.setSurfaceSize(const Size(800, 800));
      await tester.pumpWidget(
        MaterialApp(
          home: BookmarkGridViewTestHarness(
            recipes: testRecipes,
            testColumnCount: 3, 
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, equals(3),
          reason: 'Grid should have our fixed test column count of 3');
      await tester.binding.setSurfaceSize(null);
    });
  });
}

class BookmarkGridViewTestHarness extends StatelessWidget {
  final List<Recipe> recipes;
  final ValueChanged<Recipe>? onRecipeSelected;
  final ValueChanged<String>? onToggleBookmark;
  final ScrollController? scrollController;
  final int? testColumnCount; 
  
  const BookmarkGridViewTestHarness({
    super.key,
    required this.recipes,
    this.onRecipeSelected,
    this.onToggleBookmark,
    this.scrollController,
    this.testColumnCount,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: recipes.isEmpty
          ? _buildEmptyState(context)
          : GridView.builder(
              controller: scrollController,
              key: const PageStorageKey<String>('bookmarks_grid_test'),
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: testColumnCount ?? ResponsiveHelper.recipeGridColumns(context),
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return RecipeGridCard(
                  recipe: recipe,
                  onTap: () {
                    if (onRecipeSelected != null) {
                      onRecipeSelected!(recipe);
                    }
                  },
                  onDragLeft: () {
                    if (onToggleBookmark != null) {
                      onToggleBookmark!(recipe.id);
                    }
                  },
                  showBookmarkIcon: true,
                );
              },
            ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bookmark_border,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No bookmarked recipes yet',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Add recipes to your bookmarks to see them here',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}