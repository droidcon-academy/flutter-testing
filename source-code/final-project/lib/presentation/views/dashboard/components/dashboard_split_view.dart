import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'favorites/favorites_view.dart';
import 'bookmarks/bookmarks_view.dart';

class DashboardSplitView extends ConsumerStatefulWidget {
  const DashboardSplitView({
    super.key,
    this.onRecipeSelected,
  });

  final ValueChanged<Recipe>? onRecipeSelected;

  @override
  ConsumerState<DashboardSplitView> createState() => _DashboardSplitViewState();
}

class _DashboardSplitViewState extends ConsumerState<DashboardSplitView> {
  final ScrollController _favoritesScrollController = ScrollController();
  final ScrollController _bookmarksScrollController = ScrollController();

  @override
  void dispose() {
    _favoritesScrollController.dispose();
    _bookmarksScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight * 0.8),
        child: AppBar(
          title: const Text('My Dashboard'),
          centerTitle: true,
        ),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: FavoritesView(
              onRecipeSelected: widget.onRecipeSelected,
            ),
          ),
          
          const VerticalDivider(width: 1, thickness: 1),
          
          Expanded(
            flex: 1,
            child: BookmarksView(
              onRecipeSelected: widget.onRecipeSelected,
            ),
          ),
        ],
      ),
    );
  }
}
