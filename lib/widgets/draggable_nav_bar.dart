import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DraggableNavBar extends StatefulWidget {
  final bool isPlaying;
  final String exerciseTitle;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final VoidCallback onNext;

  const DraggableNavBar({
    super.key,
    required this.isPlaying,
    required this.exerciseTitle,
    required this.onPlayPause,
    required this.onStop,
    required this.onNext,
  });

  @override
  State<DraggableNavBar> createState() => _DraggableNavBarState();
}

class _DraggableNavBarState extends State<DraggableNavBar> {
  double navBarHeight = 160;
  final double minHeight = 160;
  final double maxHeight = 300;

  @override
  Widget build(BuildContext context) {
    return Positioned(
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
          duration: const Duration(milliseconds: 50),
          height: navBarHeight,
          decoration: const BoxDecoration(
            color: Color(0xFF212121),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Stack(
            children: [
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

              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSvgButton(
                          assetPath: 'assets/arret.svg',
                          color: const Color(0xFFB26231),
                          onPressed: widget.onStop,
                        ),
                        _buildSvgButton(
                          assetPath: widget.isPlaying
                              ? 'assets/stop.svg'
                              : 'assets/play.svg',
                          color: const Color(0xFFFF6200),
                          onPressed: widget.onPlayPause,
                        ),
                        _buildSvgButton(
                          gifUrl:
                              'https://media.tenor.com/OnDzyRpUwGgAAAAj/run-run-run-brawl-stars-el-primo-gif.gif', // EL PRRRRRRRRRRRIIIIIIIIIIIIIIIIIMO
                          color: const Color(0xFF454545),
                          onPressed: widget.onNext,
                          size: 65,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.exerciseTitle,
                      style: const TextStyle(
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
    );
  }

  Widget _buildSvgButton({
    String? assetPath,
    String? gifUrl,
    required Color color,
    required VoidCallback onPressed,
    double size = 30,
  }) {
    final double buttonPadding = gifUrl != null
        ? 10
        : 24;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: EdgeInsets.all(buttonPadding),
        backgroundColor: color,
      ),
      child: gifUrl != null
          ? ClipOval(
              child: Image.network(
                gifUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            )
          : SvgPicture.asset(
              assetPath!,
              width: size,
              height: size,
              color: Colors.white,
            ),
    );
  }
}
