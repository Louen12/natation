import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/counter_page.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Compteur de tractions',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const CounterPage(),
    );
  }
}
