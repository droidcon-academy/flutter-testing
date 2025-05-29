import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/recipe.dart';
import '../../overlays/heart_overlay.dart';
import '../../../widgets/common/feedback/interaction_feedback.dart';

class RecipeGridCard extends StatefulWidget {
  const RecipeGridCard({
    super.key,
    required this.recipe,
    this.onDoubleTap,
    this.onDragLeft,
    this.showBookmarkIcon = false,
    this.showFavoriteIcon = false,
    this.onTap,
  });

  final Recipe recipe;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onDragLeft;
  final bool showBookmarkIcon;
  final bool showFavoriteIcon;
  final VoidCallback? onTap;

  @override
  State<RecipeGridCard> createState() => _RecipeGridCardState();
}

class _RecipeGridCardState extends State<RecipeGridCard> {
  bool _showHeartOverlay = false;
  Offset _tapPosition = Offset.zero;

  void _handleDoubleTap(TapDownDetails details) {
    if (widget.onDoubleTap != null) {
      setState(() {
        _showHeartOverlay = true;
        _tapPosition = details.globalPosition;
      });
      
      InteractionFeedback.medium(); 
      widget.onDoubleTap!();

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _showHeartOverlay = false);
        }
      });
    }
  }

  String _getIngredientPreview() {
    if (widget.recipe.ingredients.isEmpty) return '';
    final previewCount = widget.recipe.ingredients.length > 3 ? 3 : widget.recipe.ingredients.length;
    final preview = widget.recipe.ingredients
        .take(previewCount)
        .map((i) => i.name)
        .join(', ');
    return previewCount < widget.recipe.ingredients.length 
        ? '$preview, and ${widget.recipe.ingredients.length - previewCount} more'
        : preview;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTapDown: _handleDoubleTap,
      child: Stack(
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            elevation: 4.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: widget.recipe.thumbnailUrl != null
                      ? Image.network(
                          widget.recipe.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 48.0,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.restaurant,
                            size: 48.0,
                            color: Colors.grey,
                          ),
                        ),
                ),

                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(Sizes.spacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.recipe.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        _getIngredientPreview(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (widget.showFavoriteIcon && widget.recipe.isFavorite)
            const Positioned(
              top: 8.0,
              right: 8.0,
              child: Icon(
                Icons.favorite,
                color: Colors.red,
                size: 24.0,
              ),
            ),

          if (widget.showBookmarkIcon && widget.recipe.isBookmarked)
            const Positioned(
              top: 8.0,
              left: 8.0,
              child: Icon(
                Icons.bookmark,
                color: Colors.blue,
                size: 24.0,
              ),
            ),

          if (_showHeartOverlay)
            HeartOverlay(
              isVisible: _showHeartOverlay,
              position: _tapPosition,
            ),
        ],
      ),
    );
  }
}