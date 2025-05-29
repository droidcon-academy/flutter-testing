import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../common/layout/responsive_layout_builder.dart';

class LetterItem extends StatelessWidget {
  const LetterItem({
    super.key,
    required this.letter,
    required this.onTap,
    this.isSelected = false,
  });

  final String letter;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);


    final textStyle = theme.textTheme.titleLarge?.copyWith(
      color: isSelected ? theme.colorScheme.primary : null,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onTap();
        },
        child: ResponsiveLayoutBuilder(
          mobile: _buildListItem(textStyle),
          tablet: _buildGridItem(textStyle),
          desktopWeb: _buildGridItem(textStyle),
        ),
      ),
    );
  }

  Widget _buildGridItem(TextStyle? textStyle) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? textStyle?.color ?? Colors.transparent
              : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: textStyle?.copyWith(
            fontSize: textStyle.fontSize! * 1.5,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildListItem(TextStyle? textStyle) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 56,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Sizes.spacing,
          vertical: Sizes.smallSpacing,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                letter,
                style: textStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: textStyle?.color,
            ),
          ],
        ),
      ),
    );
  }
}
