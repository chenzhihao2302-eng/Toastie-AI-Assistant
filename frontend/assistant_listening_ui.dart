import 'package:flutter/material.dart';
import 'package:toastie/themes/colors.dart';

class AssistantListeningUI extends StatelessWidget {
  const AssistantListeningUI({
    required this.rippleController,
    required this.rippleAnimation,
    required this.glowPulseAnimation,
    required this.soundLevel,
    required this.transcriptionText,
    required this.onStop,
    required this.onHome,
    required this.scrollController,
    this.listeningImagePath,
    super.key,
  });
  final AnimationController rippleController;
  final Animation<double> rippleAnimation;
  final Animation<double> glowPulseAnimation;
  final double soundLevel;
  final String transcriptionText;
  final VoidCallback onStop;
  final VoidCallback onHome;
  final ScrollController scrollController;
  final String? listeningImagePath;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: rippleController,
            builder: (context, child) {
              double pulseValue = glowPulseAnimation.value;

              double voiceValue = soundLevel;
              // Mix the continuous pulse with the voice level
              double combinedIntensity = voiceValue * 10 * pulseValue;
              double spread = 0 + (combinedIntensity * 10.0);
              double blur = 0 + (combinedIntensity * 5.0);

              return Container(
                height: 150, // Fixed height
                width: 150, // Fixed width
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
                      // Apply animated values
                      blurRadius: blur,
                      spreadRadius: spread,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    listeningImagePath ?? 'assets/defaultProfilePicture.png',
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          Container(
            height: 200,
            width: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Scrollbar(
              thumbVisibility: true,
              controller: scrollController, // Fixed: Use the passed controller
              child: SingleChildScrollView(
                controller:
                    scrollController, // Fixed: Use the passed controller
                child: Text(
                  transcriptionText.isEmpty
                      ? "Listening..."
                      : transcriptionText, // Fixed: Use passed text
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: onStop,
                icon: const Icon(Icons.stop, color: Colors.white),
                label: const Text('Stop'),
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
