import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:recipevault/core/constants/app_constants.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import 'package:recipevault/presentation/widgets/recipe/list/recipe_list_item.dart';

class BookmarkListView extends ConsumerWidget {
  const BookmarkListView({
    super.key,
    required this.recipes,
    this.onRecipeSelected,
    this.storageKey = 'bookmark_list',
    this.scrollController,
  });

  final List<Recipe> recipes;
  final ValueChanged<Recipe>? onRecipeSelected;
  final String storageKey;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: PageStorage(
        bucket: PageStorageBucket(),
        child: SlidableAutoCloseBehavior(
          closeWhenOpened: false,
          child: recipes.isEmpty
              ? _buildEmptyState(context)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      width: constraints.maxWidth < 300 ? 300 : constraints.maxWidth,
                      child: ListView.separated(
                        controller: scrollController,
                        key: PageStorageKey<String>(storageKey),
                        padding: const EdgeInsets.symmetric(vertical: Sizes.spacing),
                        itemCount: recipes.length,
                        separatorBuilder: (context, index) => const Divider(height: 2),
                        itemBuilder: (context, index) {
                          final recipe = recipes[index];
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              return SizedBox(
                                width: constraints.maxWidth < 300 ? 300 : constraints.maxWidth,
                                child: Slidable(
                                  key: Key(recipe.id),
                                  closeOnScroll: false,
                                  endActionPane: ActionPane(
                                    motion: const DrawerMotion(),
                                    extentRatio: 0.25, 
                                    dismissible: null,
                                    children: [
                                      CustomSlidableAction(
                                        onPressed: (context) {
                                          ref.read(recipeProvider.notifier).toggleBookmark(recipe.id);
                                        },
                                        autoClose: false,
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
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
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
          const SizedBox(height: Sizes.spacing),
          Text(
            'No bookmarked recipes yet',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Sizes.spacing),
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
