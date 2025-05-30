import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/presentation/widgets/recipe/list/recipe_list_item.dart';

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
    ];
  });

  group('BookmarkListView UI Tests', () {
    testWidgets('displays recipes in list format', (WidgetTester tester) async {
    
      await tester.pumpWidget(
        MaterialApp(
          home: BookmarkListViewTestHarness(
            recipes: testRecipes,
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      expect(find.byType(ListView), findsOneWidget,
          reason: 'Should display recipes in a ListView');
      expect(find.text('Test Recipe 1'), findsOneWidget,
          reason: 'Should display the first recipe name');
      expect(find.text('Test Recipe 2'), findsOneWidget,
          reason: 'Should display the second recipe name');
      expect(find.byType(RecipeListItem), findsNWidgets(2),
          reason: 'Should display 2 RecipeListItem widgets');
    });
    
    testWidgets('displays empty state when no recipes available', (WidgetTester tester) async {
  
      await tester.pumpWidget(
        const MaterialApp(
          home: BookmarkListViewTestHarness(
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
    
    testWidgets('properly responds to recipe selection', (WidgetTester tester) async {
      
      Recipe? selectedRecipe;
      await tester.pumpWidget(
        MaterialApp(
          home: BookmarkListViewTestHarness(
            recipes: testRecipes,
            onRecipeSelected: (recipe) {
              selectedRecipe = recipe;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Test Recipe 1').first);
      await tester.pumpAndSettle();
      
      expect(selectedRecipe, equals(testRecipes[0]),
          reason: 'Should call onRecipeSelected with the tapped recipe');
    });
  });

  group('BookmarkListView Interaction Tests', () {
    testWidgets('supports slide actions for removing bookmarks', (WidgetTester tester) async {
     
      String? toggledRecipeId;
      await tester.pumpWidget(
        MaterialApp(
          home: BookmarkListViewTestHarness(
            recipes: testRecipes,
            onToggleBookmark: (recipeId) {
              toggledRecipeId = recipeId;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      final slidable = find.byType(Slidable).first;
      await tester.drag(slidable, const Offset(-300, 0)); 
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      
      expect(toggledRecipeId, equals(testRecipes[0].id),
          reason: 'Should call onToggleBookmark with the correct recipe ID');
    });
  });
}

class BookmarkListViewTestHarness extends StatelessWidget {
  final List<Recipe> recipes;
  final ValueChanged<Recipe>? onRecipeSelected;
  final ValueChanged<String>? onToggleBookmark;
  final ScrollController? scrollController;
  
  const BookmarkListViewTestHarness({
    super.key,
    required this.recipes,
    this.onRecipeSelected,
    this.onToggleBookmark,
    this.scrollController,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: recipes.isEmpty
          ? _buildEmptyState(context)
          : SlidableAutoCloseBehavior(
              closeWhenOpened: true,
              child: ListView.separated(
                controller: scrollController,
                key: const PageStorageKey<String>('bookmarks_list_test'),
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: recipes.length,
                separatorBuilder: (context, index) => const Divider(height: 2),
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return Slidable(
                    key: Key(recipe.id),
                    closeOnScroll: false,
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      extentRatio: 0.25,
                      children: [
                        CustomSlidableAction(
                          onPressed: (context) {
                            if (onToggleBookmark != null) {
                              onToggleBookmark!(recipe.id);
                            }
                          },
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bookmark_remove),
                              SizedBox(height: 4),
                              Text('Remove', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    child: RecipeListItem(
                      recipe: recipe,
                      onTap: () {
                        if (onRecipeSelected != null) {
                          onRecipeSelected!(recipe);
                        }
                      },
                    ),
                  );
                },
              ),
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