import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'favorites/favorites_view.dart';
import 'bookmarks/bookmarks_view.dart';

class DashboardTabLayout extends ConsumerStatefulWidget {
  const DashboardTabLayout({
    super.key,
    this.onRecipeSelected,
  });

  final ValueChanged<Recipe>? onRecipeSelected;

  @override
  ConsumerState<DashboardTabLayout> createState() => _DashboardTabLayoutState();
}

class _DashboardTabLayoutState extends ConsumerState<DashboardTabLayout> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.favorite),
              text: 'Favorites',
            ),
            Tab(
              icon: Icon(Icons.bookmark),
              text: 'Bookmarks',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FavoritesView(
            onRecipeSelected: widget.onRecipeSelected,
          ),
          
          BookmarksView(
            onRecipeSelected: widget.onRecipeSelected,
          ),
        ],
      ),
    );
  }
}
