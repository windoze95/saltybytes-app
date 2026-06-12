import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:saltybytes_app/features/recipe/widgets/allergen_badge.dart';

import '../../../helpers/pump_helpers.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AllergenBadge full mode', () {
    testWidgets('renders the label text', (tester) async {
      await tester.pumpWidget(testApp(const AllergenBadge(
        label: 'Peanuts',
        severity: AllergenSeverity.unsafe,
      )));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Peanuts'), findsOneWidget);
      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('tints the label by severity', (tester) async {
      await tester.pumpWidget(testApp(Builder(builder: (context) {
        return const Column(children: [
          AllergenBadge(label: 'safe-item', severity: AllergenSeverity.safe),
          AllergenBadge(
              label: 'caution-item', severity: AllergenSeverity.caution),
          AllergenBadge(
              label: 'unsafe-item', severity: AllergenSeverity.unsafe),
        ]);
      })));
      await tester.pump(const Duration(milliseconds: 100));

      Color colorOf(String label) =>
          tester.widget<Text>(find.text(label)).style!.color!;

      final context = tester.element(find.byType(Column));
      final colors = Theme.of(context).colorScheme;

      expect(colorOf('safe-item'), colors.tertiary);
      expect(colorOf('caution-item'), const Color(0xFFE65100));
      expect(colorOf('unsafe-item'), colors.error);
    });
  });

  group('AllergenBadge compact mode', () {
    testWidgets('renders a severity dot with a tooltip instead of text',
        (tester) async {
      await tester.pumpWidget(testApp(const AllergenBadge(
        label: 'Gluten',
        severity: AllergenSeverity.caution,
        compact: true,
      )));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Gluten'), findsNothing);
      expect(find.byTooltip('Gluten (caution)'), findsOneWidget);
    });
  });
}
