import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:saltybytes_app/core/network/websocket_client.dart';
import 'package:saltybytes_app/core/providers/recipe_provider.dart';
import 'package:saltybytes_app/core/voice/speech_service.dart';
import 'package:saltybytes_app/features/cooking/cooking_mode_screen.dart';
import 'package:saltybytes_app/models/recipe.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_helpers.dart';

/// Silences the wakelock_plus pigeon channel (the screen toggles the
/// wakelock in initState/dispose); replies with the pigeon "success"
/// envelope. Handlers are reset by the binding after each test.
void _mockWakelockChannel(WidgetTester tester) {
  const codec = StandardMessageCodec();
  tester.binding.defaultBinaryMessenger.setMockMessageHandler(
    'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
    (message) async => codec.encodeMessage(<Object?>[null]),
  );
}

final _recipe = Recipe.fromJson(testRecipeJson(
  id: 'r-1',
  imageUrl: null,
  instructions: [
    'Preheat oven to 475F',
    'Roll out the dough',
    'Add the toppings',
    'Bake until bubbling',
  ],
));

Widget _buildScreen(FakeWebSocketClient ws, FakeSpeechService speech) {
  return testAppScaffold(
    const CookingModeScreen(recipeId: 'r-1'),
    overrides: [
      recipeDetailProvider.overrideWith((ref, id) async => _recipe),
      websocketClientProvider.overrideWithValue(ws),
      speechServiceProvider.overrideWithValue(speech),
    ],
  );
}

/// Pumps short frames so the session init + step animations settle without
/// pumpAndSettle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late FakeWebSocketClient ws;
  late FakeSpeechService speech;

  setUp(() {
    ws = FakeWebSocketClient();
    speech = FakeSpeechService();
  });

  group('CookingModeScreen steps', () {
    testWidgets('renders the first step and the progress counter',
        (tester) async {
      _mockWakelockChannel(tester);
      await tester.pumpWidget(_buildScreen(ws, speech));
      await _settle(tester);

      expect(ws.connectedRecipeId, 'r-1');
      expect(find.text('Step 1 of 4'), findsOneWidget);
      expect(find.text('Preheat oven to 475F'), findsOneWidget);
    });

    testWidgets('next/prev arrows move between steps and notify the server',
        (tester) async {
      _mockWakelockChannel(tester);
      await tester.pumpWidget(_buildScreen(ws, speech));
      await _settle(tester);

      await tester.tap(find.byIcon(Icons.arrow_forward_ios));
      await _settle(tester);

      expect(find.text('Step 2 of 4'), findsOneWidget);
      expect(find.text('Roll out the dough'), findsOneWidget);
      expect(ws.sent.last, {
        'type': 'step_change',
        'payload': {'step': 1},
      });

      await tester.tap(find.byIcon(Icons.arrow_back_ios));
      await _settle(tester);

      expect(find.text('Step 1 of 4'), findsOneWidget);
      expect(find.text('Preheat oven to 475F'), findsOneWidget);
      expect(ws.sent.last, {
        'type': 'step_change',
        'payload': {'step': 0},
      });
    });
  });

  group('CookingModeScreen chat overlay', () {
    testWidgets('opens via Ask Salty and sends a chat_message envelope',
        (tester) async {
      _mockWakelockChannel(tester);
      await tester.pumpWidget(_buildScreen(ws, speech));
      await _settle(tester);

      expect(find.text('Ask a question...'), findsNothing);

      await tester.tap(find.text('Ask Salty'));
      await _settle(tester);

      expect(find.text('Ask a question...'), findsOneWidget);

      await tester.enterText(
          find.byType(TextField), 'Can I use honey instead of sugar?');
      await tester.tap(find.byIcon(Icons.send));
      await _settle(tester);

      expect(ws.sent.last, {
        'type': 'chat_message',
        'payload': {'message': 'Can I use honey instead of sugar?'},
      });
      // The user's message renders as a bubble.
      expect(find.text('Can I use honey instead of sugar?'), findsOneWidget);
    });

    testWidgets('renders an incoming chat_response as an assistant bubble',
        (tester) async {
      _mockWakelockChannel(tester);
      await tester.pumpWidget(_buildScreen(ws, speech));
      await _settle(tester);

      await tester.tap(find.text('Ask Salty'));
      await _settle(tester);

      ws.emit({
        'type': 'chat_response',
        'payload': {'message': 'Yes — use about 3/4 the amount of honey.'},
      });
      await _settle(tester);

      expect(
        find.text('Yes — use about 3/4 the amount of honey.'),
        findsOneWidget,
      );
    });
  });

  group('CookingModeScreen mic button', () {
    testWidgets('reflects the listening state of the speech service',
        (tester) async {
      _mockWakelockChannel(tester);
      await tester.pumpWidget(_buildScreen(ws, speech));
      await _settle(tester);

      // Idle: outline mic, no live transcript.
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsNothing);
      expect(find.text('Listening…'), findsNothing);

      await tester.tap(find.byIcon(Icons.mic_none));
      await _settle(tester);

      // Listening: filled mic + live transcript line.
      expect(speech.initializeCalled, isTrue);
      expect(speech.listenCalled, isTrue);
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byIcon(Icons.mic_none), findsNothing);
      expect(find.text('Listening…'), findsOneWidget);

      // Partial transcripts stream into the live caption.
      speech.resultListener!('set a timer for ten', false);
      await _settle(tester);
      expect(find.text('set a timer for ten'), findsOneWidget);

      // The final result stops listening and sends the transcript envelope.
      speech.resultListener!('set a timer for ten minutes', true);
      await _settle(tester);
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsNothing);
      expect(ws.sent.last, {
        'type': 'voice_transcript',
        'payload': {'transcript': 'set a timer for ten minutes'},
      });
    });

    testWidgets('shows mic_off when speech recognition is unavailable',
        (tester) async {
      _mockWakelockChannel(tester);
      speech.available = false;

      await tester.pumpWidget(_buildScreen(ws, speech));
      await _settle(tester);

      await tester.tap(find.byIcon(Icons.mic_none));
      await _settle(tester);

      expect(find.byIcon(Icons.mic_off), findsOneWidget);
      expect(
        find.text('Voice input is unavailable. Check microphone permissions.'),
        findsOneWidget,
      );
    });
  });
}
