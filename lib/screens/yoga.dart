import 'package:flutter/material.dart';

class YogaPage extends StatefulWidget {
  final String title;

  const YogaPage({super.key, required this.title});

  @override
  State<YogaPage> createState() => _YogaPageState();
}

class _YogaPageState extends State<YogaPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [Text("Yoga ici")],
        ),
      ),
    );
  }
}
