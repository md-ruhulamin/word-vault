// lib/models/quiz_result.dart

enum QuizType { words, bookmarked, idioms, mixed }

class QuizResult {
  final int totalQuestions;
  final int correctAnswers;
  final QuizType quizType;
  final DateTime completedAt;

  QuizResult({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.quizType,
    DateTime? completedAt,
  }) : completedAt = completedAt ?? DateTime.now();

  double get score =>
      totalQuestions > 0 ? correctAnswers / totalQuestions : 0.0;

  int get percentage => (score * 100).round();
}
