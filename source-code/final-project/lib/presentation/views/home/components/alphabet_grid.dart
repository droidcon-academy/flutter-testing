import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../home_screen.dart';
import '../../../widgets/alphabet/letter_item.dart';

class AlphabetGrid extends ConsumerWidget {
  const AlphabetGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final letters = List.generate(26, (index) => String.fromCharCode(65 + index));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Vault'),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: ResponsiveHelper.screenPadding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveHelper.alphabetGridColumns,
          childAspectRatio: 1,
          crossAxisSpacing: Sizes.spacing,
          mainAxisSpacing: Sizes.spacing,
        ),
        itemCount: letters.length,
        itemBuilder: (context, index) {
          return LetterItem(
            letter: letters[index],
            onTap: () {
              ref.read(selectedLetterProvider.notifier).state = letters[index];
              ref.read(recipeProvider.notifier).setSelectedLetter(letters[index]);
            },
          );
        },
      ),
    );
  }
}