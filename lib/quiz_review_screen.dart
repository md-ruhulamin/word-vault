// lib/screens/quiz_review_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vocab_store/app_theme.dart';
import 'package:vocab_store/quiz_attempt.dart';

// ─── Result screen shown right after submission ───────────────────────────────

class QuizResultScreen extends StatelessWidget {
  final QuizAttempt attempt;
  final Color accentColor;

  const QuizResultScreen({
    super.key,
    required this.attempt,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final pct = attempt.percentage;
    final wrongItems =
        attempt.questions.where((q) => !q.isCorrect).toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Score hero ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withOpacity(0.25),
                      accentColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(attempt.emoji,
                        style: const TextStyle(fontSize: 52)),
                    const SizedBox(height: 12),
                    Text(attempt.message,
                        style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 4),
                    Text(attempt.modeTitle,
                        style: GoogleFonts.inter(
                            color: AppTheme.textSecondary, fontSize: 13)),
                    const SizedBox(height: 24),

                    // Big score
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$pct',
                            style: GoogleFonts.spaceGrotesk(
                              color: accentColor,
                              fontSize: 72,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            )),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text('%',
                              style: GoogleFonts.spaceGrotesk(
                                color: accentColor.withOpacity(0.7),
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Stats row
                    Row(
                      children: [
                        _StatBox(
                          value: '${attempt.correctCount}',
                          label: 'Correct',
                          color: AppTheme.accent,
                        ),
                        const SizedBox(width: 10),
                        _StatBox(
                          value: '${attempt.wrongCount}',
                          label: 'Wrong',
                          color: AppTheme.rose,
                        ),
                        const SizedBox(width: 10),
                        _StatBox(
                          value: '${attempt.totalQuestions}',
                          label: 'Total',
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Grade badge ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    _GradeBadge(grade: attempt.grade, color: accentColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _gradeMessage(attempt.grade),
                        style: GoogleFonts.inter(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                    Text(
                      _formatDate(attempt.completedAt),
                      style: GoogleFonts.inter(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            // ── Wrong answers section ─────────────────────────────────────────
            if (wrongItems.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.highlight_off,
                          color: AppTheme.rose, size: 20),
                      const SizedBox(width: 8),
                      Text('Incorrect Answers (${wrongItems.length})',
                          style: GoogleFonts.spaceGrotesk(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _ReviewCard(
                      question: wrongItems[i],
                      index: i,
                      isCorrect: false,
                    ),
                  ),
                  childCount: wrongItems.length,
                ),
              ),
            ],

            // ── Correct answers section ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppTheme.accent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                        'Correct Answers (${attempt.correctCount})',
                        style: GoogleFonts.spaceGrotesk(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final correct = attempt.questions
                      .where((q) => q.isCorrect)
                      .toList()[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _ReviewCard(
                      question: correct,
                      index: i,
                      isCorrect: true,
                    ),
                  );
                },
                childCount: attempt.correctCount,
              ),
            ),

            // ── Action buttons ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.popUntil(context, (r) => r.isFirst),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: AppTheme.bg,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14)),
                        icon: const Icon(Icons.home_outlined, size: 18),
                        label: Text('Back to Home',
                            style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          side: const BorderSide(color: AppTheme.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Try Again'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _gradeMessage(String grade) {
    switch (grade) {
      case 'S': return 'Outstanding! You nailed it!';
      case 'A': return 'Excellent! Keep it up!';
      case 'B': return 'Good work! A little more practice!';
      case 'C': return 'Fair. Review the wrong answers below.';
      default: return 'Keep studying! You\'ll get there!';
    }
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

// ─── History attempt detail screen ───────────────────────────────────────────

class AttemptDetailScreen extends StatelessWidget {
  final QuizAttempt attempt;

  const AttemptDetailScreen({super.key, required this.attempt});

  @override
  Widget build(BuildContext context) {
    final wrongItems = attempt.questions.where((q) => !q.isCorrect).toList();
    final correctItems = attempt.questions.where((q) => q.isCorrect).toList();
    final accentColor = _modeColor(attempt.mode);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App bar ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: AppTheme.textSecondary, size: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(attempt.modeTitle,
                              style: GoogleFonts.spaceGrotesk(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          Text(_formatDate(attempt.completedAt),
                              style: GoogleFonts.inter(
                                  color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    _GradeBadge(grade: attempt.grade, color: accentColor),
                  ],
                ),
              ),
            ),

            // ── Summary card ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatBox(
                        value: '${attempt.percentage}%',
                        label: 'Score',
                        color: accentColor),
                    _StatBox(
                        value: '${attempt.correctCount}',
                        label: 'Correct',
                        color: AppTheme.accent),
                    _StatBox(
                        value: '${attempt.wrongCount}',
                        label: 'Wrong',
                        color: AppTheme.rose),
                    _StatBox(
                        value: '${attempt.totalQuestions}',
                        label: 'Total',
                        color: AppTheme.textSecondary),
                  ],
                ),
              ),
            ),

            // ── Wrong answers ────────────────────────────────────────────────
            if (wrongItems.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.highlight_off,
                          color: AppTheme.rose, size: 20),
                      const SizedBox(width: 8),
                      Text('Wrong (${wrongItems.length})',
                          style: GoogleFonts.spaceGrotesk(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _ReviewCard(
                        question: wrongItems[i], index: i, isCorrect: false),
                  ),
                  childCount: wrongItems.length,
                ),
              ),
            ],

            // ── Correct answers ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppTheme.accent, size: 20),
                    const SizedBox(width: 8),
                    Text('Correct (${correctItems.length})',
                        style: GoogleFonts.spaceGrotesk(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _ReviewCard(
                      question: correctItems[i], index: i, isCorrect: true),
                ),
                childCount: correctItems.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  Color _modeColor(String mode) {
    switch (mode) {
      case 'words': return AppTheme.accent;
      case 'bookmarked': return AppTheme.gold;
      case 'idioms': return const Color(0xFF9D78F5);
      case 'mixed': return AppTheme.rose;
      default: return AppTheme.accent;
    }
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final QuizQuestion question;
  final int index;
  final bool isCorrect;

  const _ReviewCard({
    required this.question,
    required this.index,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect
              ? AppTheme.accent.withOpacity(0.25)
              : AppTheme.rose.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isCorrect
                      ? AppTheme.accent.withOpacity(0.15)
                      : AppTheme.rose.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCorrect ? Icons.check : Icons.close,
                  color: isCorrect ? AppTheme.accent : AppTheme.rose,
                  size: 15,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            question.type == 'word' ? 'WORD' : 'IDIOM',
                            style: GoogleFonts.spaceGrotesk(
                                color: AppTheme.textSecondary,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(question.question,
                        style: GoogleFonts.spaceGrotesk(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 12),

          // Correct answer
          _AnswerRow(
            label: 'Correct answer',
            value: question.correctAnswer,
            color: AppTheme.accent,
            icon: Icons.check_circle,
          ),

          // Wrong chosen answer (only if wrong)
          if (!isCorrect) ...[
            const SizedBox(height: 8),
            _AnswerRow(
              label: 'Your answer',
              value: question.chosenAnswer.isEmpty
                  ? '(not answered)'
                  : question.chosenAnswer,
              color: AppTheme.rose,
              icon: Icons.cancel,
            ),
          ],

          // All options
          if (question.options.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('All options:',
                style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: question.options.map((opt) {
                final isCorrectOpt = opt == question.correctAnswer;
                final isChosen = opt == question.chosenAnswer;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isCorrectOpt
                        ? AppTheme.accent.withOpacity(0.12)
                        : (isChosen && !isCorrect)
                            ? AppTheme.rose.withOpacity(0.1)
                            : AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCorrectOpt
                          ? AppTheme.accent.withOpacity(0.4)
                          : (isChosen && !isCorrect)
                              ? AppTheme.rose.withOpacity(0.4)
                              : AppTheme.border,
                    ),
                  ),
                  child: Text(opt,
                      style: GoogleFonts.inter(
                          color: isCorrectOpt
                              ? AppTheme.accent
                              : (isChosen && !isCorrect)
                                  ? AppTheme.rose
                                  : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: isCorrectOpt || (isChosen && !isCorrect)
                              ? FontWeight.w600
                              : FontWeight.w400)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _AnswerRow(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: GoogleFonts.inter(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatBox(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.spaceGrotesk(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: GoogleFonts.inter(
                  color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _GradeBadge extends StatelessWidget {
  final String grade;
  final Color color;
  const _GradeBadge({required this.grade, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Center(
        child: Text(grade,
            style: GoogleFonts.spaceGrotesk(
                color: color, fontSize: 18, fontWeight: FontWeight.w800)),
      ),
    );
  }
}
