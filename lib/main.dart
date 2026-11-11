import 'package:flutter/material.dart';

import 'screens/trivia_screen.dart';
import 'services/trivia_service.dart';

void main() => runApp(const TriviaApp());

class TriviaApp extends StatelessWidget {
  const TriviaApp({super.key, this.service});

  final TriviaService? service;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'API-to-Cloud Trivia',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006A6A)),
      useMaterial3: true,
    ),
    home: TriviaScreen(service: service ?? TriviaService()),
  );
}
