// lib/services/tts_service.dart
//
// Wraps flutter_tts with:
//  - speak(text)           — speaks any text
//  - speakWord(word)       — speaks the word itself (or pronunciation guide if set)
//  - speakSlow(text)       — 0.3 rate for careful pronunciation
//  - stop()
//  - isPlaying stream
//
// Add to pubspec.yaml:  flutter_tts: ^4.0.2

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;
  bool _initialized = false;

  bool get isSpeaking => _speaking;

  TtsService() {
    _init();
  }

  Future<void> _init() async {
    await _tts.setLanguage('en-US');
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.45);   // slightly slower than default for vocab
    await _tts.setVolume(1.0);

    _tts.setStartHandler(() {
      _speaking = true;
      notifyListeners();
    });
    _tts.setCompletionHandler(() {
      _speaking = false;
      notifyListeners();
    });
    _tts.setCancelHandler(() {
      _speaking = false;
      notifyListeners();
    });
    _tts.setErrorHandler((msg) {
      _speaking = false;
      notifyListeners();
    });

    _initialized = true;
  }

  /// Speak a word — if it has a pronunciation hint say that, else say the word.
  Future<void> speakWord(String word, {String? pronunciation}) async {
    final text = (pronunciation != null && pronunciation.trim().isNotEmpty)
        ? pronunciation
        : word;
    await speak(text);
  }

  /// Speak at careful slow rate (useful for example sentences).
  Future<void> speakSlow(String text) async {
    await _tts.setSpeechRate(0.3);
    await speak(text);
    await _tts.setSpeechRate(0.45);
  }

  /// Speak at normal rate.
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    if (_speaking) await stop();
    await _tts.speak(text.trim());
  }

  Future<void> stop() async {
    await _tts.stop();
    _speaking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}
