import 'dart:math';

import 'package:api_cloud_trivia/models/question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps and decodes a valid question', () {
    final question = Question.fromJson({
      'question': 'Tom &amp; Jerry said &quot;hi&quot; &#039;today&#039;.',
      'correct_answer': 'A &amp; B',
      'incorrect_answers': ['C', 'D', 'E'],
    }, random: Random(1));
    expect(question.text, 'Tom & Jerry said "hi" \'today\'.');
    expect(question.correctAnswer, 'A & B');
    expect(question.options, containsAll(['A & B', 'C', 'D', 'E']));
  });

  test('decodes numeric entities', () {
    expect(decodeTriviaText('&#65; &#x42;'), 'A B');
  });

  test('rejects malformed question data', () {
    expect(
      () => Question.fromJson({'question': 'Missing'}),
      throwsFormatException,
    );
  });
}
