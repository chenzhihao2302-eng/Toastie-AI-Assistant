import 'package:flutter/material.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'package:toastie/features/assistant/module/chat_module.dart';
import 'package:toastie/features/assistant/widgets/message_bubble.dart';
import 'package:toastie/features/assistant/widgets/message_field.dart';
import 'package:toastie/themes/colors.dart';
import 'package:toastie/themes/text/text.dart';
import 'package:toastie/utils/grid.dart';
import 'package:toastie/utils/layout/padding.dart';

class AssistantChatUI extends StatelessWidget {
  const AssistantChatUI({
    required this.chatItems,
    required this.scrollController,
    required this.userName,
    required this.textController,
    required this.focusNode,
    required this.onSendAttachment,
    required this.onStartListening,
    required this.onReload,
    required this.onBookDoctor,
    super.key,
  });
  final List<ChatItem> chatItems;
  final ScrollController scrollController;
  final String userName;
  final TextEditingController textController;
  final FocusNode focusNode;
  final void Function(String, dynamic) onSendAttachment;
  final VoidCallback onStartListening;
  final VoidCallback onReload;
  final VoidCallback onBookDoctor;

  final List<String> quickButtons = const [
    'Track health',
    'Ask a question',
    'Book doctor',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: chatItems.isNotEmpty
              ? ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  itemCount: chatItems.length,
                  itemBuilder: (context, index) {
                    final item = chatItems[index];
                    if (item is ChatCardItem) {
                      return Padding(
                        padding: chatInnerPadding,
                        child: item.card,
                      );
                    } else if (item is ChatMessage) {
                      return Padding(
                        padding: chatInnerPadding,
                        child: AssistantMessageBubble(item: item),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                )
              : _buildWelcomeView(context),
        ),

        // Quick Buttons (Only when empty)
        if (chatItems.isEmpty) ...[
          _buildTrackButton(context),
          const SizedBox(height: 8),
        ],

        AssistantMessageField(
          textController: textController,
          focusNode: focusNode,
          showHintText: true,
          hintText: 'Ask Toastie anything...',
          // FIX: Wrap the callback to adapt to the specific Attachment type
          onSendWithAttachment: (text, attachment) async =>
              onSendAttachment(text, attachment),
          reloadAssistantPage: onReload,
          onStartListening: onStartListening,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTrackButton(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: quickButtons.map((text) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.0),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: borderRadius),
                side: const BorderSide(color: Colors.white, width: 1),
                backgroundColor: primary[300] as Color,
              ),
              onPressed: () {
                if (text == 'Book doctor') {
                  onBookDoctor();
                  return;
                }

                if (text == 'Track health') {
                  textController.text = 'I want to track my health';
                } else if (text == 'Ask a question') {
                  textController.text = 'I have a question about my health';
                }

                textController.selection = TextSelection.fromPosition(
                  TextPosition(offset: textController.text.length),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app, color: Colors.white, size: 20),
                  SizedBox(width: gridbaseline),
                  Text(text, style: graphTooltipTextStyle()),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWelcomeView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Image(
          image: AssetImage('assets/defaultProfilePicture.png'),
          height: 200,
          fit: BoxFit.fitHeight,
        ),
        const SizedBox(height: 16),
        GradientText(
          'Hi $userName',
          style: const TextStyle(fontSize: 40, fontFamily: 'LibreBaskerville'),
          colors: [accentYellow[500]!, accentPink[600]!],
        ),
        Text(
          'How can I help you today?',
          style: displayMediumTextWithColor(
            context: context,
            color: primary[900]!,
          ).copyWith(fontSize: 40),
        ),
      ],
    );
  }
}
