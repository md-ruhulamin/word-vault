
import 'package:flutter/material.dart';
import 'package:vocab_store/audio_controller.dart';

class SpeakTheWord extends StatelessWidget {
  
  const SpeakTheWord({
    super.key,
    required this.text,
  
  });

  final String  text;


  @override
  Widget build(BuildContext context) {
    final ttsController = TTSController();
    return IconButton(
      icon: const Icon(
        Icons.volume_up,
        color: Colors.white,
        size: 18,
      ),
      onPressed: () {
        ttsController.speak(text);
      },
    
    );
  }
}
