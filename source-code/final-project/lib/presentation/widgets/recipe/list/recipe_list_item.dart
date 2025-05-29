import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/recipe.dart';

class RecipeListItem extends StatelessWidget {
  const RecipeListItem({
    super.key,
    required this.recipe,
    this.showBookmarkIcon = false,
    this.showFavoriteIcon = false,
    this.onTap,
  });

  final Recipe recipe;
  final bool showBookmarkIcon;
  final bool showFavoriteIcon;
  final VoidCallback? onTap;

  String _getIngredientPreview() {
    if (recipe.ingredients.isEmpty) return '';
    final previewCount = recipe.ingredients.length > 3 ? 3 : recipe.ingredients.length;
    final preview = recipe.ingredients
        .take(previewCount)
        .map((i) => i.name)
        .join(', ');
    return previewCount < recipe.ingredients.length 
        ? '$preview, and ${recipe.ingredients.length - previewCount} more'
        : preview;
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 300.0, 
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Sizes.spacing,
          vertical: Sizes.spacing / 2,
        ),
        leading: CircleAvatar(
          radius: 24.0,
          backgroundColor: Colors.grey[200],
          child: recipe.thumbnailUrl != null
              ? ClipOval(
                  child: Image.network(
                    recipe.thumbnailUrl!,
                    width: 48.0,
                    height: 48.0,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.restaurant,
                      size: 24.0,
                      color: Colors.grey,
                    ),
                  ),
                )
              : const Icon(
                  Icons.restaurant,
                  size: 24.0,
                  color: Colors.grey,
                ),
        ),
        title: Text(
          recipe.name,
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _getIngredientPreview(),
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}