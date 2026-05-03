// lib/models/quiz_attempt.dart

class QuizQuestion {
  final String question;
  final String correctAnswer;
  final String chosenAnswer;
  final List<String> options;
  final String type; // 'word' | 'idiom'

  QuizQuestion({
    required this.question,
    required this.correctAnswer,
    required this.chosenAnswer,
    required this.options,
    required this.type,
  });

  bool get isCorrect => chosenAnswer == correctAnswer;

  Map<String, dynamic> toMap() => {
        'question': question,
        'correctAnswer': correctAnswer,
        'chosenAnswer': chosenAnswer,
        'options': options,
        'type': type,
      };

  factory QuizQuestion.fromMap(Map<String, dynamic> map) => QuizQuestion(
        question: map['question'] ?? '',
        correctAnswer: map['correctAnswer'] ?? '',
        chosenAnswer: map['chosenAnswer'] ?? '',
        options: List<String>.from(map['options'] ?? []),
        type: map['type'] ?? 'word',
      );
}

class QuizAttempt {
  final String id;
  final String mode;
  final String modeTitle;
  final int totalQuestions;
  final int correctCount;
  final DateTime completedAt;
  final List<QuizQuestion> questions;

  QuizAttempt({
    required this.id,
    required this.mode,
    required this.modeTitle,
    required this.totalQuestions,
    required this.correctCount,
    required this.completedAt,
    required this.questions,
  });

  int get percentage =>
      totalQuestions > 0 ? (correctCount / totalQuestions * 100).round() : 0;

  int get wrongCount => totalQuestions - correctCount;

  String get grade {
    if (percentage >= 90) return 'S';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    return 'F';
  }

  String get emoji {
    if (percentage >= 80) return '🎉';
    if (percentage >= 60) return '👍';
    return '💪';
  }

  String get message {
    if (percentage >= 90) return 'Perfect score!';
    if (percentage >= 80) return 'Excellent work!';
    if (percentage >= 60) return 'Good effort!';
    return 'Keep practicing!';
  }

  Map<String, dynamic> toMap() => {
        'mode': mode,
        'modeTitle': modeTitle,
        'totalQuestions': totalQuestions,
        'correctCount': correctCount,
        'completedAt': completedAt.toIso8601String(),
        'questions': questions.map((q) => q.toMap()).toList(),
      };

  factory QuizAttempt.fromMap(String id, Map<String, dynamic> map) =>
      QuizAttempt(
        id: id,
        mode: map['mode'] ?? '',
        modeTitle: map['modeTitle'] ?? '',
        totalQuestions: map['totalQuestions'] ?? 0,
        correctCount: map['correctCount'] ?? 0,
        completedAt: DateTime.tryParse(map['completedAt'] ?? '') ??
            DateTime.now(),
        questions: (map['questions'] as List<dynamic>? ?? [])
            .map((q) => QuizQuestion.fromMap(Map<String, dynamic>.from(q)))
            .toList(),
      );
}
