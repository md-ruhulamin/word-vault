// lib/services/firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vocab_store/model/idiom.dart';
import 'package:vocab_store/quiz_attempt.dart';
import 'package:vocab_store/model/word.dart';
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // ── Auth ──────────────────────────────────────────────────────────────────

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInAnonymously() =>
      _auth.signInAnonymously();

  Future<UserCredential> signInWithEmailPassword(
          String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> registerWithEmailPassword(
          String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();

  // ── Words ─────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _wordsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('words');

  Stream<List<Word>> watchWords(String userId) {
    return _wordsRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Word.fromMap(d.id, d.data())).toList());
  }

  Future<void> addWord(String userId, Word word) =>
      _wordsRef(userId).add(word.toMap());

  Future<void> updateWord(String userId, Word word) =>
      _wordsRef(userId).doc(word.id).update(word.toMap());

  Future<void> deleteWord(String userId, String wordId) =>
      _wordsRef(userId).doc(wordId).delete();

  Future<void> toggleWordBookmark(
      String userId, String wordId, bool current) async {
    await _wordsRef(userId).doc(wordId).update({'isBookmarked': !current});
  }

  // ── Idioms ────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _idiomsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('idioms');

  Stream<List<Idiom>> watchIdioms(String userId) {
    return _idiomsRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Idiom.fromMap(d.id, d.data())).toList());
  }

  Future<void> addIdiom(String userId, Idiom idiom) =>
      _idiomsRef(userId).add(idiom.toMap());

  Future<void> updateIdiom(String userId, Idiom idiom) =>
      _idiomsRef(userId).doc(idiom.id).update(idiom.toMap());

  Future<void> deleteIdiom(String userId, String idiomId) =>
      _idiomsRef(userId).doc(idiomId).delete();

  Future<void> toggleIdiomBookmark(
      String userId, String idiomId, bool current) async {
    await _idiomsRef(userId).doc(idiomId).update({'isBookmarked': !current});
  }

  // ── Quiz Attempts ─────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _attemptsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('quizAttempts');

  Future<String> saveQuizAttempt(String userId, QuizAttempt attempt) async {
    final ref = await _attemptsRef(userId).add(attempt.toMap());
    return ref.id;
  }

  Stream<List<QuizAttempt>> watchAttempts(String userId) {
    return _attemptsRef(userId)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => QuizAttempt.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> deleteAttempt(String userId, String attemptId) =>
      _attemptsRef(userId).doc(attemptId).delete();

  // ── Bulk import from existing Firestore list ──────────────────────────────

  /// Call this once to migrate words from a top-level 'words' collection
  /// (or any flat list) into the user's sub-collection.
  Future<void> importWordsFromCollection(
      String userId, String sourceCollection) async {
    final snap = await _firestore.collection(sourceCollection).get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      final data = doc.data();
      final newRef = _wordsRef(userId).doc();
      batch.set(newRef, {
        'word': data['word'] ?? '',
        'meaning': data['meaning'] ?? '',
        'sentence': data['sentence'] ?? '',
        'isBookmarked': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
    await batch.commit();
  }
}
