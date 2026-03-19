import 'package:flutter/material.dart';
import 'package:toastie/themes/colors.dart';

class AssistantThinkingUI extends StatelessWidget {
  const AssistantThinkingUI({
    required this.glowPulseAnimation,
    required this.listeningImagePath,
    required this.onHome,
    super.key,
  });
  final Animation<double> glowPulseAnimation;
  final String? listeningImagePath;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Rainbow Pulse Animation
          AnimatedBuilder(
            animation: glowPulseAnimation,
            builder: (context, child) {
              double pulseValue = glowPulseAnimation.value;
              double blur = 1 + (pulseValue * 5);
              double spread = 10 + (pulseValue * 20);

              return Container(
                height: 150,
                width: 150,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.5),
                      blurRadius: blur,
                      spreadRadius: spread,
                    ),
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.8),
                      blurRadius: blur,
                      spreadRadius: spread * 0.85,
                    ),
                    BoxShadow(
                      color: Colors.yellow.withOpacity(0.8),
                      blurRadius: blur,
                      spreadRadius: spread * 0.70,
                    ),
                    BoxShadow(
                      color: Colors.green.withOpacity(0.8),
                      blurRadius: blur,
                      spreadRadius: spread * 0.55,
                    ),
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.8),
                      blurRadius: blur,
                      spreadRadius: spread * 0.40,
                    ),
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.8),
                      blurRadius: blur,
                      spreadRadius: spread * 0.25,
                    ),
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.8),
                      blurRadius: blur,
                      spreadRadius: spread * 0.10,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    listeningImagePath ?? 'assets/defaultProfilePicture.png',
                    fit: BoxFit.cover,
                    height: 150,
                    width: 150,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          // Thinking Text
          Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Text(
              "Thinking and generating response...",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 40),
          // Only Home button is needed while thinking (usually)
          ElevatedButton.icon(
            onPressed: onHome,
            icon: const Icon(Icons.home, color: Colors.white),
            label: const Text('Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary[400] as Color,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
