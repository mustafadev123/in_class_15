import 'package:api_cloud_trivia/main.dart';
import 'package:api_cloud_trivia/models/question.dart';
import 'package:api_cloud_trivia/services/trivia_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeService extends TriviaService {
  _FakeService(this.handler);
  final Future<List<Question>> Function() handler;
  int calls = 0;

  @override
  Future<List<Question>> fetchQuestions() {
    calls++;
    return handler();
  }
}

Question _question() => Question(
  text: 'Which planet is known as the Red Planet?',
  correctAnswer: 'Mars',
  options: const ['Venus', 'Mars', 'Jupiter', 'Mercury'],
);

void main() {
  testWidgets('shows an error and retries', (tester) async {
    var shouldFail = true;
    final service = _FakeService(() async {
      if (shouldFail) throw const TriviaException('offline');
      return [_question()];
    });
    await tester.pumpWidget(TriviaApp(service: service));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump();
    expect(find.textContaining('offline'), findsOneWidget);
    shouldFail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Red Planet'), findsOneWidget);
    expect(service.calls, 2);
  });

  testWidgets('scores once, completes, syncs, and replays', (tester) async {
    final service = _FakeService(() async => [_question()]);
    await tester.pumpWidget(TriviaApp(service: service));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mars'));
    await tester.pump();
    expect(find.text('Correct!'), findsOneWidget);
    expect(find.text('Score: 1'), findsOneWidget);
    final venus = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Venus'),
    );
    expect(venus.onPressed, isNull);
    await tester.tap(find.text('See results'));
    await tester.pumpAndSettle();
    expect(find.text('Final score: 1/1'), findsOneWidget);
    expect(find.textContaining('no data is sent'), findsOneWidget);
    await tester.tap(find.text('Simulate leaderboard sync'));
    await tester.pump(const Duration(milliseconds: 901));
    expect(find.text('Simulation completed'), findsOneWidget);
    await tester.tap(find.text('Play again'));
    await tester.pumpAndSettle();
    expect(service.calls, 2);
    expect(find.text('Score: 0'), findsOneWidget);
  });
}
