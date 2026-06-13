import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:saltybytes_app/features/recipe/widgets/instruction_list.dart';

import '../../../helpers/pump_helpers.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('InstructionList', () {
    testWidgets('renders one numbered step per instruction', (tester) async {
      await tester.pumpWidget(testApp(const InstructionList(
        instructions: [
          'Preheat oven to 475F',
          'Roll out the dough',
          'Bake until golden',
        ],
      )));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Preheat oven to 475F'), findsOneWidget);
      expect(find.text('Roll out the dough'), findsOneWidget);
      expect(find.text('Bake until golden'), findsOneWidget);
    });

    testWidgets('renders nothing for an empty instruction list',
        (tester) async {
      await tester
          .pumpWidget(testApp(const InstructionList(instructions: [])));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(InstructionList), findsOneWidget);
      expect(find.text('1'), findsNothing);
    });

    testWidgets('keeps instruction order: numbers pair with their text',
        (tester) async {
      await tester.pumpWidget(testApp(const InstructionList(
        instructions: ['First step', 'Second step'],
      )));
      await tester.pump(const Duration(milliseconds: 100));

      final firstNumber = tester.getTopLeft(find.text('1'));
      final secondNumber = tester.getTopLeft(find.text('2'));
      final firstText = tester.getTopLeft(find.text('First step'));
      final secondText = tester.getTopLeft(find.text('Second step'));

      expect(firstNumber.dy, lessThan(secondNumber.dy));
      expect(firstText.dy, lessThan(secondText.dy));
      // Each number row sits level with its instruction text.
      expect(firstNumber.dy, lessThan(secondText.dy));
    });
  });
}
