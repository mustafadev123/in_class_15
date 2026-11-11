import 'dart:math';

class Question {
  Question({
    required this.text,
    required this.correctAnswer,
    required List<String> options,
  }) : options = List.unmodifiable(options);

  factory Question.fromJson(Map<String, dynamic> json, {Random? random}) {
    final prompt = json['question'];
    final correct = json['correct_answer'];
    final incorrect = json['incorrect_answers'];
    if (prompt is! String ||
        correct is! String ||
        incorrect is! List ||
        incorrect.any((answer) => answer is! String)) {
      throw const FormatException('A trivia question has an invalid shape.');
    }
    final decodedCorrect = decodeTriviaText(correct);
    final choices = <String>[
      decodedCorrect,
      ...incorrect.cast<String>().map(decodeTriviaText),
    ]..shuffle(random ?? Random());
    return Question(
      text: decodeTriviaText(prompt),
      correctAnswer: decodedCorrect,
      options: choices,
    );
  }

  final String text;
  final String correctAnswer;
  final List<String> options;
}

String decodeTriviaText(String source) {
  const entities = <String, String>{
    '&quot;': '"',
    '&#039;': "'",
    '&apos;': "'",
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&nbsp;': ' ',
  };
  var decoded = source;
  for (final entity in entities.entries) {
    decoded = decoded.replaceAll(entity.key, entity.value);
  }
  return decoded.replaceAllMapped(RegExp(r'&#(x?[0-9A-Fa-f]+);'), (match) {
    final value = match.group(1)!;
    final radix = value.startsWith('x') ? 16 : 10;
    final digits = value.startsWith('x') ? value.substring(1) : value;
    final codePoint = int.tryParse(digits, radix: radix);
    return codePoint == null ? match.group(0)! : String.fromCharCode(codePoint);
  });
}
