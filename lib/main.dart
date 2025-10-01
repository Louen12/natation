import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'screens/sleeving_exercise.dart';
import 'widgets/ExerciseCard.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Draggable NavBar',
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isPlaying = false;
  double navBarHeight = 160;
  final double minHeight = 160;
  final double maxHeight = 300;
  String exerciseTitle = "Titre de l'exercice";
  final GlobalKey<ExerciseCardState> _cardKey = GlobalKey<ExerciseCardState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 219, 219, 219),
      body: Stack(
        children: [
          // Contenu principal
          Center(child: SleevingExercisePage(cardKey: _cardKey)),

          // Exemple si tu veux afficher ton autre page SleevingExercisePage
          // Center(child: SleevingExercisePage()),

          // Nav bar draggable
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  navBarHeight -= details.delta.dy;
                  if (navBarHeight < minHeight) navBarHeight = minHeight;
                  if (navBarHeight > maxHeight) navBarHeight = maxHeight;
                });
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 50),
                height: navBarHeight,
                decoration: BoxDecoration(
                  color: Color(0xFF212121),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Stack(
                  children: [
                    // Barre blanche fixée à 10px du haut de la nav bar
                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 200,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),

                    // Boutons et texte fixes en bas
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Boutons ronds
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildSvgButton(
                                assetPath: 'assets/arret.svg',
                                color: Color(0xFFB26231),
                                onPressed: () =>
                                    setState(() => isPlaying = false),
                              ),
                              _buildSvgButton(
                                assetPath: isPlaying ? 'assets/stop.svg' : 'assets/play.svg',
                                color: Color(0xFFFF6200),
                                onPressed: () {
                                  _cardKey.currentState?.toggleTimer();
                                  setState(() => isPlaying = !isPlaying);
                                },
                              ),
                              _buildSvgButton(
                                assetPath: 'assets/gif.svg',
                                color: Color(0xFF454545),
                                onPressed: () => setState(
                                  () => exerciseTitle = "Exercice suivant",
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 8),

                          // Texte centré
                          Text(
                            exerciseTitle,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSvgButton({
    required String assetPath,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(),
        padding: EdgeInsets.all(24),
        backgroundColor: color,
      ),
      child: SvgPicture.asset(
        assetPath,
        width: 30,
        height: 30,
        color: Colors.white,
      ),
    );
  }
}
