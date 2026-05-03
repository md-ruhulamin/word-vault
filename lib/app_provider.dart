import 'package:flutter/material.dart';
import 'package:vocab_store/model/idiom.dart';
import 'package:vocab_store/quiz_attempt.dart';
import 'package:vocab_store/model/word.dart';
import 'firebase_service.dart';

class AppProvider extends ChangeNotifier {
  final FirebaseService _fb = FirebaseService();

  List<Word> _words = [];
  List<Idiom> _idioms = [];
  List<QuizAttempt> _attempts = [];
  bool _loading = false;
  String? _userId;

  List<Word> get words => _words;
  List<Word> get bookmarkedWords => _words.where((w) => w.isBookmarked).toList();
  List<Idiom> get idioms => _idioms;
  List<Idiom> get bookmarkedIdioms => _idioms.where((i) => i.isBookmarked).toList();
  List<QuizAttempt> get attempts => _attempts;
  bool get loading => _loading;
  String? get userId => _userId;
  FirebaseService get fb => _fb;

  // ── NEW: words that have synonyms / antonyms filled in ────────────────────
  List<Word> get wordsWithSynonyms =>
      _words.where((w) => w.synonyms.isNotEmpty).toList();

  List<Word> get wordsWithAntonyms =>
      _words.where((w) => w.antonyms.isNotEmpty).toList();
  // ─────────────────────────────────────────────────────────────────────────

  int get totalQuizzesTaken => _attempts.length;
  double get averageScore {
    if (_attempts.isEmpty) return 0;
    return _attempts.map((a) => a.percentage).reduce((a, b) => a + b) /
        _attempts.length;
  }
  int get bestScore {
    if (_attempts.isEmpty) return 0;
    return _attempts
        .map((a) => a.percentage)
        .reduce((a, b) => a > b ? a : b);
  }
  int get totalQuestionsAnswered =>
      _attempts.fold(0, (s, a) => s + a.totalQuestions);
  int get totalCorrect => _attempts.fold(0, (s, a) => s + a.correctCount);

  void init(String userId) {
    _userId = userId;
    _fb.watchWords(userId).listen((list) { _words = list; notifyListeners(); });
    _fb.watchIdioms(userId).listen((list) { _idioms = list; notifyListeners(); });
    _fb.watchAttempts(userId).listen((list) { _attempts = list; notifyListeners(); });
  }

  Future<void> addWord(Word word) async { if (_userId == null) return; await _fb.addWord(_userId!, word); }
  Future<void> updateWord(Word word) async { if (_userId == null) return; await _fb.updateWord(_userId!, word); }
  Future<void> deleteWord(String id) async { if (_userId == null) return; await _fb.deleteWord(_userId!, id); }
  Future<void> toggleWordBookmark(Word word) async { if (_userId == null) return; await _fb.toggleWordBookmark(_userId!, word.id, word.isBookmarked); }
  Future<void> addIdiom(Idiom idiom) async { if (_userId == null) return; await _fb.addIdiom(_userId!, idiom); }
  Future<void> updateIdiom(Idiom idiom) async { if (_userId == null) return; await _fb.updateIdiom(_userId!, idiom); }
  Future<void> deleteIdiom(String id) async { if (_userId == null) return; await _fb.deleteIdiom(_userId!, id); }
  Future<void> toggleIdiomBookmark(Idiom idiom) async { if (_userId == null) return; await _fb.toggleIdiomBookmark(_userId!, idiom.id, idiom.isBookmarked); }
  Future<void> saveQuizAttempt(QuizAttempt attempt) async { if (_userId == null) return; await _fb.saveQuizAttempt(_userId!, attempt); }
  Future<void> deleteAttempt(String id) async { if (_userId == null) return; await _fb.deleteAttempt(_userId!, id); }

  List<Map<String, String>> getQuizItems(String mode) {
    List<Map<String, String>> items = [];
    switch (mode) {
      case 'words':
        items = _words
            .map((w) => {'question': w.word, 'answer': w.meaning, 'type': 'word'})
            .toList();
        break;

      case 'bookmarked':
        items = [
          ..._words.where((w) => w.isBookmarked).map((w) => {'question': w.word, 'answer': w.meaning, 'type': 'word'}),
          ..._idioms.where((i) => i.isBookmarked).map((i) => {'question': i.phrase, 'answer': i.meaning, 'type': 'idiom'}),
        ];
        break;

      case 'idioms':
        items = _idioms
            .map((i) => {'question': i.phrase, 'answer': i.meaning, 'type': 'idiom'})
            .toList();
        break;

      case 'mixed':
        items = [
          ..._words.map((w) => {'question': w.word, 'answer': w.meaning, 'type': 'word'}),
          ..._idioms.map((i) => {'question': i.phrase, 'answer': i.meaning, 'type': 'idiom'}),
        ];
        break;

      // ── NEW: Synonym quiz ─────────────────────────────────────────────────
      // Question: the word itself
      // Answer:   one of its synonyms (we create one entry per synonym)
      // Wrong options are built in quiz_screen.dart from the answer pool
      case 'synonyms':
        for (final w in wordsWithSynonyms) {
          for (final syn in w.synonyms) {
            items.add({
              'question': w.word,
              'answer': syn,
              'type': 'synonym',
              'questionLabel': 'Find a SYNONYM',
            });
          }
        }
        break;

      // ── NEW: Antonym quiz ─────────────────────────────────────────────────
      case 'antonyms':
        for (final w in wordsWithAntonyms) {
          for (final ant in w.antonyms) {
            items.add({
              'question': w.word,
              'answer': ant,
              'type': 'antonym',
              'questionLabel': 'Find an ANTONYM',
            });
          }
        }
        break;
    }

    items.shuffle();
    return items.take(20).toList();
  }
}
