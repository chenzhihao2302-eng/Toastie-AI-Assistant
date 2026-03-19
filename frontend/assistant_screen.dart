import 'dart:io';
import 'dart:typed_data';
import 'dart:convert' show jsonDecode;
import 'package:flutter/material.dart';
import 'package:toastie/features/assistant/services/response_parser.dart';
import 'package:toastie/features/assistant/widgets/assistant_chat_ui.dart';
import 'package:toastie/features/assistant/widgets/assistant_listening_ui.dart';
import 'package:toastie/features/assistant/widgets/assistant_response_ui.dart';
import 'package:toastie/features/assistant/widgets/assistant_speaking_ui.dart';
import 'package:toastie/features/assistant/widgets/assistant_thinking_ui.dart';
import 'package:toastie/features/assistant/widgets/hopital_card.dart';
import 'package:toastie/shared/widgets/layout/layout.dart';
import 'package:toastie/themes/colors.dart';
import 'package:toastie/services/location_storage_utils.dart';
import 'package:toastie/features/assistant/http/send_to_server.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:toastie/features/assistant/services/hospital_service.dart';
import 'package:toastie/features/assistant/module/chat_module.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

BoxDecoration assistantGradientBackground = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.center,
    colors: [
      accentPink[300] as Color,
      primary[200] as Color,
      primary[100] as Color,
    ],
  ),
);

// extend mode states (keep original idle/listening/aiResponse idea)
enum AssistantMode { idle, listening, aiResponse, aiThinking, aiSpeaking }

class _AssistantScreenState extends State<AssistantScreen>
    with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // 1. Core UI State & Mode
  // ---------------------------------------------------------------------------

  /// Controls the current view state (e.g., Listening, Thinking, Speaking, Idle).
  AssistantMode _mode = AssistantMode.idle;

  /// Controls the focus of the text input field.
  final FocusNode _focusNode = FocusNode();

  // ---------------------------------------------------------------------------
  // 2. Chat List & Input Management
  // ---------------------------------------------------------------------------

  /// Stores the list of messages (User text, AI text, Cards) to display.
  final List<ChatItem> chatItems = [];

  /// Controls the text input field for manual typing.
  final TextEditingController _controller = TextEditingController();

  /// Controls scrolling for the main chat list.
  final ScrollController _chatScrollController = ScrollController();

  // Configuration for the input field hint.
  final bool showHintText = true;
  final String hintText = 'Ask Toastie anything...';

  // ---------------------------------------------------------------------------
  // 3. Session & User Data
  // ---------------------------------------------------------------------------

  /// The unique ID of the current conversation session (initialized as "null").
  late String _id;

  /// The user's display name, fetched from cache.
  String _userName = '';

  // ---------------------------------------------------------------------------
  // 4. Speech-to-Text (STT) - Input
  // ---------------------------------------------------------------------------

  /// The Speech Recognition engine instance.
  late stt.SpeechToText _speech;

  /// Scroll controller specifically for the STT preview box (the floating text).
  final ScrollController _sttScrollController = ScrollController();

  /// Buffer to hold words as they are recognized before sending.
  String _transcriptionText = "";

  /// Current microphone volume level (0.0 to 1.0) used for the ripple animation.
  double _soundLevel = 0.0;

  // ---------------------------------------------------------------------------
  // 5. Text-to-Speech (TTS) - Output
  // ---------------------------------------------------------------------------

  /// The Text-to-Speech engine instance.
  final FlutterTts _flutterTts = FlutterTts();

  /// Buffer to hold the text currently being spoken by the AI (for the typewriter effect).
  String _aiResponseText = "";

  // ---------------------------------------------------------------------------
  // 6. Audio & Assets
  // ---------------------------------------------------------------------------

  /// Handles playback of UI sound effects (e.g., 'start_listening.wav').
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Path to the image displayed inside the center avatar (profile pic or logo).
  String? _listeningImagePath;

  // ---------------------------------------------------------------------------
  // 7. Animation Controllers
  // ---------------------------------------------------------------------------

  // --- A. Ripple Animation (Used during 'Listening' state) ---
  /// Main controller for the breathing/ripple effect.
  late AnimationController _rippleController;

  /// Animation for the size of the outer ripple.
  late Animation<double> _rippleAnimation;

  /// Animation for the glow opacity/intensity.
  late Animation<double> _glowPulseAnimation;

  /// Animation for the border pulse effect.
  late Animation<double> _borderPulseAnimation;

  // --- B. Speech Pulse Animation (Used during 'Speaking' state) ---
  /// Controller for the quick "pop" effect when the AI speaks a word.
  late AnimationController _speechPulseController;

  /// Animation value determining how much the avatar grows when a word is spoken.
  late Animation<double> _speechPulseAnimation;

  @override
  void initState() {
    super.initState();
    _id = "null";
    _speech = stt.SpeechToText();

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowPulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeInOut),
    );

    _rippleAnimation = Tween<double>(
      begin: 150,
      end: 200,
    ).animate(_rippleController);

    _borderPulseAnimation = Tween<double>(begin: 156.0, end: 200.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeInOut),
    );

    _speechPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _speechPulseAnimation = Tween<double>(begin: 1.0, end: 8).animate(
      CurvedAnimation(parent: _speechPulseController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchName());
  }

  Future _fetchName() async {
    final name = await getNameFromCache();
    if (!mounted) return;
    setState(() {
      _userName = name;
    });
  }

  Future _reloadAssistantPage() async {
    await _fetchName();

    setState(() {
      chatItems.clear();
      _controller.clear();
    });

    if (_chatScrollController.hasClients) {
      _chatScrollController.jumpTo(0);
    }
  }

  Future<void> _startListening() async {
    _transcriptionText = "";

    bool available = await _speech.initialize(
      onError: (err) => debugPrint("STT error: $err"),
      onStatus: (status) => debugPrint("STT status: $status"),
    );

    if (available) {
      await _speech.listen(
        listenMode: stt.ListenMode.confirmation,
        onSoundLevelChange: (level) {
          setState(() {
            // We assume 'level' is a dB value, e.g., -60 to 0.
            // We normalize it to a 0.0 - 1.0 range.
            // You may need to adjust -60 (silence) if your mic is different.
            _soundLevel = ((level + 60) / 60).clamp(0.0, 1.0);
          });
        },
        onResult: (result) {
          setState(() {
            _transcriptionText = result.recognizedWords;
          });
          Future.delayed(const Duration(milliseconds: 60), () {
            if (_sttScrollController.hasClients) {
              _sttScrollController.jumpTo(
                _sttScrollController.position.maxScrollExtent,
              );
            }
          });
        },
      );
      setState(() {
        _mode = AssistantMode.listening;
      });
    } else {
      debugPrint("STT not available");
    }
  }

  Future<void> _stopListeningAndSend({bool sendToBackend = true}) async {
    // Handle "Home/Cancel" button click
    if (!sendToBackend) {
      setState(() {
        _transcriptionText = "";
        _mode = AssistantMode.idle;
      });
      return;
    }

    final text = _transcriptionText.trim();
    // Handle Empty Input
    if (text.isEmpty) {
      setState(() {
        _mode = AssistantMode.idle;
      });
      return;
    }

    // Update UI to "Thinking" state
    setState(() {
      _transcriptionText = ""; // Clear buffer
      _mode = AssistantMode.aiThinking;
      _aiResponseText = ""; // Reset AI text buffer
    });

    // Add User Message to Chat UI immediately
    chatItems.add(ChatMessage(text, true));

    try {
      // Send to Server (Async call happens OUTSIDE setState)
      final res = await SendToServer.sendToServerMultipart(_id, text, []);

      // Decode JSON
      final raw = res['data'] ?? res['body'] ?? res;
      final Map<String, dynamic> decoded = raw is String
          ? Map<String, dynamic>.from(jsonDecode(raw))
          : Map<String, dynamic>.from(raw as Map);

      //  Parse the Response
      final ChatItem responseItem = ResponseParser.parseResponse(decoded);
      chatItems.add(responseItem);

      // Trigger TTS (AI Speaking) logic
      if (responseItem is ChatMessage && !responseItem.isUser) {
        await _startAITalking(responseItem.text);
      } else {
        // If it's a Card (Widget), don't read it, just show UI
        setState(() => _mode = AssistantMode.aiResponse);
      }
    } catch (e) {
      debugPrint("Error in send: $e");
      chatItems.add(ChatMessage("Error: $e", false));
      setState(() {
        _mode = AssistantMode.idle;
      });
    }
  }

  // AI speaking + center subtitle box
  Future<void> _startAITalking(String text) async {
    if (!mounted || text.trim().isEmpty) return;

    setState(() {
      _mode = AssistantMode.aiSpeaking;
      _aiResponseText = "";
    });

    // Setup TTS and start speaking immediately
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.awaitSpeakCompletion(true);

      // Trigger pulse animation when a new word is spoken
      _flutterTts.setProgressHandler((
        String fullText,
        int startIndex,
        int endIndex,
        String word,
      ) {
        if (!mounted) return;
        _speechPulseController.forward(from: 0.0).then((_) {
          if (mounted) {
            _speechPulseController.reverse();
          }
        });
      });

      // When TTS finishes, go back
      _flutterTts.setCompletionHandler(() {
        if (!mounted) return;
        setState(() {});
        _speechPulseController.value = 0.0;
      });

      // Do NOT await here, let TTS run in parallel with typing
      _flutterTts.speak(text);
    } catch (e) {
      debugPrint("TTS error: $e");
      if (!mounted) return;
      setState(() {
        _mode = AssistantMode.idle;
      });
      return;
    }

    // Typing animation for the subtitle box (runs in parallel with TTS)
    for (int i = 0; i < text.length; i++) {
      await Future.delayed(const Duration(milliseconds: 18));
      // If user navigates away or mode changed, stop typing
      if (!mounted || _mode != AssistantMode.aiSpeaking) {
        return;
      }
      setState(() {
        _aiResponseText += text[i];
      });
    }
  }

  Future<void> _handleBookDoctor() async {
    final loadingIndex = chatItems.length;

    // Add Loading Bubble
    chatItems.add(
      ChatMessage('Fetching nearby hospitals...', false, isLoading: true),
    );
    setState(() {});

    try {
      // Call the Service (The logic is now moved here)
      final List<String> items = await HospitalService.fetchNearbyHospitals();

      // Remove Loading Bubble
      chatItems.removeAt(loadingIndex);

      // Handle Success
      if (items.isEmpty) {
        chatItems.add(ChatMessage('No nearby hospitals found.', false));
      } else {
        chatItems.add(
          ChatMessage(
            "I've helped you find nearby hospitals for booking.",
            false,
          ),
        );
        // Add the Card Widget
        chatItems.add(ChatCardItem(NearbyHospitalsCard(items: items)));
      }
    } catch (e) {
      // Handle Errors

      // Safely remove loading bubble if it hasn't been removed yet
      // (We check if the item at loadingIndex is actually the loading message)
      if (loadingIndex < chatItems.length &&
          chatItems[loadingIndex] is ChatMessage &&
          (chatItems[loadingIndex] as ChatMessage).isLoading) {
        chatItems.removeAt(loadingIndex);
      }

      // Clean up the exception message (remove "Exception: " prefix)
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      chatItems.add(ChatMessage('Error: $errorMessage', false));
    }

    // 6. Update UI and Scroll
    setState(() {});

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessageWithAttachment(
    String text, {
    File? file,
    Uint8List? bytes,
    String? imageUrl,
    String? caption,
  }) async {
    if (text.trim().isEmpty &&
        file == null &&
        bytes == null &&
        imageUrl == null) {
      return;
    }

    // Add User Message immediately
    chatItems.add(
      ChatMessage(
        text,
        true,
        localFile: file,
        bytes: bytes,
        imageUrl: imageUrl,
        caption: caption,
      ),
    );
    setState(() {}); // Update UI to show user message

    try {
      // Prepare files for upload
      final files = <Uint8List>[];
      if (bytes != null) {
        files.add(bytes);
      } else if (file != null) {
        files.add(await file.readAsBytes());
      }

      // Send to Server
      final res = await SendToServer.sendToServerMultipart(_id, text, files);
      final raw = res['data'] ?? res['body'] ?? res;
      final Map<String, dynamic> decoded = raw is String
          ? Map<String, dynamic>.from(jsonDecode(raw))
          : Map<String, dynamic>.from(raw as Map);

      // Parse Response using the Helper Class
      final ChatItem newItem = ResponseParser.parseResponse(decoded);
      chatItems.add(newItem);
    } catch (e) {
      chatItems.add(ChatMessage('Error: $e', false));
    }

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Final UI update
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _chatScrollController.dispose();
    _focusNode.dispose();
    _rippleController.dispose();
    _speechPulseController.dispose();
    _audioPlayer.dispose();
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      color: assistantGradientBackground,
      childInFactionallySizedBox: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _buildCurrentModeUI(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentModeUI(BuildContext context) {
    switch (_mode) {
      case AssistantMode.listening:
        return AssistantListeningUI(
          rippleController: _rippleController,
          rippleAnimation: _rippleAnimation,
          glowPulseAnimation: _glowPulseAnimation,
          soundLevel: _soundLevel,
          transcriptionText: _transcriptionText,

          onStop: () => _stopListeningAndSend(sendToBackend: true),
          onHome: () => _stopListeningAndSend(sendToBackend: false),
          scrollController: _sttScrollController,
          listeningImagePath: _listeningImagePath,
        );
      case AssistantMode.aiResponse:
        return AssistantResponseUI(
          borderPulseAnimation: _borderPulseAnimation,
          listeningImagePath: _listeningImagePath,
          chatItems: chatItems,
          onContinue: _startListening,
          onHome: () {
            setState(() {
              _mode = AssistantMode.idle;
            });
          },
        );
      case AssistantMode.aiThinking:
        return AssistantThinkingUI(
          glowPulseAnimation: _glowPulseAnimation,
          listeningImagePath: _listeningImagePath,
          onHome: () {
            setState(() {
              _mode = AssistantMode.idle;
            });
          },
        );
      case AssistantMode.aiSpeaking:
        return AssistantSpeakingUI(
          aiResponseText: _aiResponseText,
          listeningImagePath: _listeningImagePath,
          glowPulseAnimation: _glowPulseAnimation,
          speechPulseAnimation: _speechPulseAnimation,
          onContinue: _startListening,
          onHome: () {
            setState(() {
              _mode = AssistantMode.idle;
            });
          },
        );
      case AssistantMode.idle:
        return AssistantChatUI(
          chatItems: chatItems,
          scrollController: _chatScrollController,
          userName: _userName,
          textController: _controller,
          focusNode: _focusNode,
          onSendAttachment: (text, att) async {
            _sendMessageWithAttachment(
              text,
              file: att?.file,
              bytes: att?.bytes,
            );
            setState(() {});
          },
          onStartListening: _startListening,
          onReload: _reloadAssistantPage,
          onBookDoctor: _handleBookDoctor,
        );
    }
  }
}
