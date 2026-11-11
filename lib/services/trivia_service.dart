import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/question.dart';

class TriviaService {
  TriviaService({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  static final Uri endpoint = Uri.https('opentdb.com', '/api.php', {
    'amount': '5',
    'category': '9',
    'difficulty': 'easy',
    'type': 'multiple',
  });

  final http.Client _client;
  final Duration timeout;

  Future<List<Question>> fetchQuestions() async {
    final response = await _client.get(endpoint).timeout(timeout);
    if (response.statusCode != 200) {
      throw TriviaException(
        'The trivia server returned HTTP ${response.statusCode}.',
      );
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const TriviaException('The trivia server returned invalid JSON.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const TriviaException('The trivia response has an invalid shape.');
    }
    if (decoded['response_code'] != 0) {
      throw TriviaException(
        'The trivia API could not provide questions (code ${decoded['response_code']}).',
      );
    }
    final results = decoded['results'];
    if (results is! List || results.isEmpty) {
      throw const TriviaException('No trivia questions were returned.');
    }
    try {
      return results
          .map((item) => Question.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } on TypeError {
      throw const TriviaException(
        'The question data is incomplete or invalid.',
      );
    } on FormatException {
      throw const TriviaException(
        'The question data is incomplete or invalid.',
      );
    }
  }
}

class TriviaException implements Exception {
  const TriviaException(this.message);
  final String message;
  @override
  String toString() => message;
}
