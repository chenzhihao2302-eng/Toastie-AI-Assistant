import 'package:flutter/material.dart';
import 'package:toastie/themes/colors.dart';

class AssistantSpeakingUI extends StatelessWidget {
  const AssistantSpeakingUI({
    required this.aiResponseText,
    required this.listeningImagePath,
    required this.glowPulseAnimation,
    required this.speechPulseAnimation,
    required this.onContinue,
    required this.onHome,
    super.key,
  });
  final String aiResponseText;
  final String? listeningImagePath;
  final Animation<double> glowPulseAnimation;
  final Animation<double> speechPulseAnimation;
  final VoidCallback onContinue;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Typing Pop + Breathing Animation
          AnimatedBuilder(
            animation: Listenable.merge([
              glowPulseAnimation,
              speechPulseAnimation,
            ]),
            builder: (context, child) {
              double pulseValue = glowPulseAnimation.value;
              double popValue = speechPulseAnimation.value;

              double blur = (10 + (pulseValue * 10)) * popValue;
              double spread = (5 + (pulseValue * 5)) * popValue;

              return Container(
                height: 150,
                width: 150,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(
                        255,
                        247,
                        197,
                        117,
                      ).withOpacity(0.6),
                      blurRadius: blur,
                      spreadRadius: spread,
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
          // Response Text
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: 1.0,
            child: Container(
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
              child: Text(
                aiResponseText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.black87),
              ),
            ),
          ),
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
                    horizontal: 24,
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
                    horizontal: 24,
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
