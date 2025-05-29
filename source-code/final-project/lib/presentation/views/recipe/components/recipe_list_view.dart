import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:recipevault/core/constants/app_constants.dart';
import 'package:recipevault/core/utils/responsive_helper.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import 'package:recipevault/presentation/views/home/home_screen.dart';
import 'package:recipevault/presentation/views/recipe/components/recipe_panel.dart';
import 'package:recipevault/presentation/widgets/recipe/list/recipe_list_item.dart';

class RecipeListView extends ConsumerWidget {
  const RecipeListView({
    super.key,
    this.onRecipeSelected,
    this.scrollController,
    this.storageKey = 'recipeListView',
  });

  final ValueChanged<Recipe>? onRecipeSelected;
  final ScrollController? scrollController;
  final String storageKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recipeProvider);
    final recipes = state.recipes;
    final deviceType = ResponsiveSizes.whichDevice();
    
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 300.0, 
      ),
      child: Scaffold(
        appBar: deviceType == ResponsiveSizes.mobile
            ? null
            : AppBar(
                title: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.list),
                    SizedBox(width: 8),
                    Text('Recipe List'),
                  ],
                ),
                centerTitle: true,
              ),
        body: PageStorage(
          bucket: pageStorageBucket,
          child: SlidableAutoCloseBehavior(
            closeWhenOpened: false,
            child: recipes.isEmpty
                ? Consumer(
                    builder: (context, ref, child) {
                      final selectedLetter = ref.watch(selectedLetterProvider);
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.no_meals,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              selectedLetter != null
                                  ? "No recipes found for letter '${selectedLetter.toUpperCase()}'"
                                  : "No recipes found",
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : ListView.separated(
                    controller: scrollController,
                    key: PageStorageKey<String>(storageKey),
                    padding: const EdgeInsets.symmetric(vertical: Sizes.spacing),
                    itemCount: recipes.length,
                    separatorBuilder: (context, index) => const Divider(height: 2),
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return Slidable(
                        key: Key(recipe.id),
                        closeOnScroll: false,
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.5,
                          dismissible: null,
                          children: [
                            CustomSlidableAction(
                              onPressed: (context) {
                                ref.read(recipeProvider.notifier).toggleFavorite(recipe.id);
                              },
                              autoClose: false, 
                              backgroundColor: const Color(0xFFFCE4EC),
                              foregroundColor: Colors.red,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    recipe.isFavorite ? Icons.favorite : Icons.favorite_outline,
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('Favorite', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            CustomSlidableAction(
                              onPressed: (context) {
                                ref.read(recipeProvider.notifier).toggleBookmark(recipe.id);
                              },
                              autoClose: false, 
                              backgroundColor: const Color(0xFFE3F2FD), 
                              foregroundColor: Colors.blue,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    recipe.isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('Bookmark', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        child: RecipeListItem(
                          recipe: recipe,
                          showBookmarkIcon: false,
                          showFavoriteIcon: false,
                          onTap: () => onRecipeSelected?.call(recipe),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
