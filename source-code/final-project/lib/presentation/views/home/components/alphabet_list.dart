import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../viewmodels/recipe_viewmodel.dart';
import '../../../widgets/alphabet/letter_item.dart';
import '../home_screen.dart';

class AlphabetList extends ConsumerWidget {
  const AlphabetList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final letters = List.generate(26, (index) => String.fromCharCode(65 + index));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Vault'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: ResponsiveHelper.screenPadding,
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