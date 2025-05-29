import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/core/constants/app_constants.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/presentation/viewmodels/dashboard_viewmodel.dart';
import 'bookmark_grid_view.dart';
import 'bookmark_list_view.dart';

class BookmarksView extends ConsumerStatefulWidget {
  const BookmarksView({
    super.key,
    this.onRecipeSelected,
  });

  final ValueChanged<Recipe>? onRecipeSelected;

  @override
  ConsumerState<BookmarksView> createState() => _BookmarksViewState();
}

class _BookmarksViewState extends ConsumerState<BookmarksView> {
  bool _showGridView = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final bookmarkedRecipes = dashboardState.bookmarkedRecipes;
    final isLoading = dashboardState.isLoading || dashboardState.isPartiallyLoaded;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
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
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: Sizes.spacing),
                  Text(
                    'Loading bookmarks...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : bookmarkedRecipes.isEmpty
              ? _buildEmptyState()
              : _showGridView
                  ? BookmarkGridView(
                      recipes: bookmarkedRecipes,
                      onRecipeSelected: widget.onRecipeSelected,
                      storageKey: 'bookmarks_grid',
                      scrollController: _scrollController,
                    )
                  : BookmarkListView(
                      recipes: bookmarkedRecipes,
                      onRecipeSelected: widget.onRecipeSelected,
                      storageKey: 'bookmarks_list',
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
