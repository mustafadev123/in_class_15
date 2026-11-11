import 'dart:async';

import 'package:flutter/material.dart';

import '../models/question.dart';
import '../services/trivia_service.dart';

class TriviaScreen extends StatefulWidget {
  const TriviaScreen({super.key, required this.service});
  final TriviaService service;

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> {
  List<Question> _questions = const [];
  int _questionIndex = 0;
  int _score = 0;
  String? _selectedAnswer;
  String? _error;
  bool _loading = true;
  bool _syncing = false;
  bool _scoreSynced = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;
      _error = null;
      _questions = const [];
      _questionIndex = 0;
      _score = 0;
      _selectedAnswer = null;
      _scoreSynced = false;
    });
    try {
      final questions = await widget.service.fetchQuestions();
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _loading = false;
      });
    } on TimeoutException {
      _showLoadError('The request timed out. Check your connection and retry.');
    } catch (error) {
      _showLoadError('Could not load trivia: $error');
    }
  }

  void _showLoadError(String message) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = message;
    });
  }

  void _selectAnswer(String answer) {
    if (_selectedAnswer != null) return;
    setState(() {
      _selectedAnswer = answer;
      if (answer == _questions[_questionIndex].correctAnswer) _score++;
    });
  }

  void _continue() {
    setState(() {
      _questionIndex++;
      _selectedAnswer = null;
    });
  }

  Future<void> _simulateScoreSync() async {
    setState(() => _syncing = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _syncing = false;
      _scoreSynced = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Simulation complete: score $_score/${_questions.length} prepared.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Trivia Showdown'), centerTitle: true),
    body: SafeArea(child: _buildBody()),
  );

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Fetching five live questions…'),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 56),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadQuestions,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_questionIndex >= _questions.length) return _buildResults();
    return _buildQuestion(_questions[_questionIndex]);
  }

  Widget _buildQuestion(Question question) {
    final answered = _selectedAnswer != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Question ${_questionIndex + 1} of ${_questions.length}'),
            Text('Score: $_score'),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: (_questionIndex + 1) / _questions.length,
        ),
        const SizedBox(height: 28),
        Semantics(
          header: true,
          child: Text(
            question.text,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 24),
        for (final option in question.options) ...[
          _AnswerButton(
            label: option,
            state: !answered
                ? _AnswerState.unanswered
                : option == question.correctAnswer
                ? _AnswerState.correct
                : option == _selectedAnswer
                ? _AnswerState.incorrect
                : _AnswerState.neutral,
            onPressed: answered ? null : () => _selectAnswer(option),
          ),
          const SizedBox(height: 12),
        ],
        if (answered) ...[
          const SizedBox(height: 8),
          Text(
            _selectedAnswer == question.correctAnswer
                ? 'Correct!'
                : 'Not quite. The correct answer is ${question.correctAnswer}.',
            key: const Key('answer-feedback'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _continue,
            child: Text(
              _questionIndex == _questions.length - 1
                  ? 'See results'
                  : 'Next question',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResults() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 72),
          const SizedBox(height: 16),
          Text(
            'Round complete',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Final score: $_score/${_questions.length}',
            key: const Key('final-score'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _syncing || _scoreSynced ? null : _simulateScoreSync,
            icon: _syncing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload),
            label: Text(
              _scoreSynced
                  ? 'Simulation completed'
                  : _syncing
                  ? 'Simulating…'
                  : 'Simulate leaderboard sync',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Classroom simulation only — no data is sent to a backend.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _loadQuestions,
            icon: const Icon(Icons.replay),
            label: const Text('Play again'),
          ),
        ],
      ),
    ),
  );
}

enum _AnswerState { unanswered, correct, incorrect, neutral }

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.state,
    required this.onPressed,
  });
  final String label;
  final _AnswerState state;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (state) {
      _AnswerState.correct => (Colors.green.shade700, Colors.white),
      _AnswerState.incorrect => (colors.error, colors.onError),
      _AnswerState.neutral => (
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
      ),
      _AnswerState.unanswered => (colors.surface, colors.onSurface),
    };
    return Semantics(
      label: switch (state) {
        _AnswerState.correct => '$label, correct answer',
        _AnswerState.incorrect => '$label, incorrect selection',
        _ => label,
      },
      button: true,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            backgroundColor: background,
            foregroundColor: foreground,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
          onPressed: onPressed,
          child: Text(label),
        ),
      ),
    );
  }
}
