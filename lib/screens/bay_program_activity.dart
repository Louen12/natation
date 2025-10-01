import 'package:flutter/material.dart';

class BayProgramActivity extends StatefulWidget {
  const BayProgramActivity({Key? key}) : super(key: key);

  @override
  _BayProgramActivityState createState() => _BayProgramActivityState();
}

class _BayProgramActivityState extends State<BayProgramActivity> {
  final List<String> activity = <String>['Pompe', 'Traction', 'Abdo'];
  final List<int> colorCodes = <int>[600, 500, 100];

  final List<int> repetition = <int>[4, 5, 3];

  final List<int> serie = <int>[10, 5, 20];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: activity.length,
        itemBuilder: (BuildContext context, int index) {
          String text = '${repetition[index]} x ${serie[index]} ${activity[index]}';
          return Container(
            color: Colors.amber[colorCodes[index]],
            child: Center(child: Text(text,   style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.5),
            )),
          );
        },
        separatorBuilder: (BuildContext context, int index) => const Divider(),
      )
    );
  }
}
