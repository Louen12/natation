import 'package:flutter/material.dart';

class ProgramPage extends StatefulWidget {
  final String title;

  const ProgramPage({super.key, required this.title});

  @override
  State<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [Text("Program ici")],
        ),
      ),
    );
  }
}
