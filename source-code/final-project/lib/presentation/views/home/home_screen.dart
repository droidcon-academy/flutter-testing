// Container for A-Z display
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/common/layout/responsive_layout_builder.dart';
import '../recipe/recipe_screen.dart';
import 'components/alphabet_grid.dart';
import 'components/alphabet_list.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLetterSelected = ref.watch(selectedLetterProvider) != null;

    if (!isLetterSelected) {
      return const ResponsiveLayoutBuilder(
        mobile: AlphabetList(),
        tablet: AlphabetGrid(),
        desktopWeb: AlphabetGrid(),
      );
    } else {
      return const RecipeScreen();
    }
  }
}

final selectedLetterProvider = StateProvider<String?>((ref) => null);