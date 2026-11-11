import 'package:api_cloud_trivia/services/trivia_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('requests the required endpoint and parses questions', () async {
    final client = MockClient((request) async {
      expect(request.url, TriviaService.endpoint);
      return http.Response('''{"response_code":0,"results":[{
        "question":"Two &amp; two?","correct_answer":"Four",
        "incorrect_answers":["One","Two","Three"]}]}''', 200);
    });
    final questions = await TriviaService(client: client).fetchQuestions();
    expect(questions, hasLength(1));
    expect(questions.single.text, 'Two & two?');
  });

  test('rejects an unsuccessful HTTP status', () async {
    final service = TriviaService(
      client: MockClient((_) async => http.Response('unavailable', 503)),
    );
    await expectLater(
      service.fetchQuestions(),
      throwsA(isA<TriviaException>()),
    );
  });

  test('rejects a nonzero API response code', () async {
    final service = TriviaService(
      client: MockClient(
        (_) async => http.Response('{"response_code":1,"results":[]}', 200),
      ),
    );
    await expectLater(
      service.fetchQuestions(),
      throwsA(isA<TriviaException>()),
    );
  });
}
