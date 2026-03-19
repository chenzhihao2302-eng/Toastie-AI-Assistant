import 'package:flutter/material.dart';
import 'package:toastie/themes/colors.dart';
import 'package:toastie/utils/layout/padding.dart';

class AssistantResponseUI extends StatelessWidget {
  const AssistantResponseUI({
    required this.borderPulseAnimation,
    required this.listeningImagePath,
    required this.chatItems,
    required this.onContinue,
    required this.onHome,
    super.key,
  });
  final Animation<double> borderPulseAnimation;
  final String? listeningImagePath;
  final VoidCallback onContinue;
  final VoidCallback onHome;
  final List chatItems;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: borderPulseAnimation,
            builder: (context, child) {
              return Container(
                height: borderPulseAnimation.value,
                width: borderPulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    startAngle: 0.0,
                    endAngle: 2 * 3.14159,
                    colors: <Color>[
                      Colors.red.withOpacity(0.6),
                      Colors.orange.withOpacity(0.6),
                      Colors.yellow.withOpacity(0.6),
                      Colors.green.withOpacity(0.6),
                      Colors.blue.withOpacity(0.6),
                      Colors.indigo.withOpacity(0.6),
                      Colors.purple.withOpacity(0.6),
                      Colors.red.withOpacity(0.6),
                    ],
                    stops: const <double>[
                      0.0,
                      0.14,
                      0.28,
                      0.42,
                      0.56,
                      0.70,
                      0.84,
                      1.0,
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: child,
              );
            },
            child: Container(
              height: 150,
              width: 150,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              clipBehavior: Clip.hardEdge,
              child: Image.asset(
                listeningImagePath ?? 'assets/defaultProfilePicture.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            "AI response",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.black87),
          ),

          Padding(padding: chatInnerPadding, child: chatItems.last.card),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.mic, color: Colors.white),
                label: const Text('Continue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: onHome,
                icon: const Icon(Icons.home, color: Colors.white),
                label: const Text('Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary[400] as Color,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
