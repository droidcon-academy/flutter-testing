import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/core/constants/app_constants.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/presentation/viewmodels/dashboard_viewmodel.dart';
import 'favorite_grid_view.dart';
import 'favorite_list_view.dart';

/// A dedicated view for displaying favorite recipes
class FavoritesView extends ConsumerStatefulWidget {
  const FavoritesView({
    super.key,
    this.onRecipeSelected,
  });

  final ValueChanged<Recipe>? onRecipeSelected;

  @override
  ConsumerState<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends ConsumerState<FavoritesView> {
  bool _showGridView = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get dashboard state to check both favorites and loading status
    final dashboardState = ref.watch(dashboardProvider);
    final favoriteRecipes = dashboardState.favoriteRecipes;
    final isLoading = dashboardState.isLoading || dashboardState.isPartiallyLoaded;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        centerTitle: true,
        actions: [
          // Toggle between list and grid view
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
      body: isLoading
          // Show loading indicator when loading favorites
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: Sizes.spacing),
                  Text(
                    'Loading favorites...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : favoriteRecipes.isEmpty
              ? _buildEmptyState()
              : _showGridView
                  ? FavoriteGridView(
                      recipes: favoriteRecipes,
                      onRecipeSelected: widget.onRecipeSelected,
                      storageKey: 'favorites_grid',
                      scrollController: _scrollController,
                    )
                  : FavoriteListView(
                      recipes: favoriteRecipes,
                      onRecipeSelected: widget.onRecipeSelected,
                      storageKey: 'favorites_list',
                      scrollController: _scrollController,
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: Sizes.spacing),
          Text(
            'No favorite recipes yet',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Sizes.spacing),
          Text(
            'Add recipes to your favorites to see them here',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
