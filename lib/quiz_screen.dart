// lib/screens/quiz_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vocab_store/app_provider.dart';
import 'package:vocab_store/app_theme.dart';
import 'package:vocab_store/quiz_attempt.dart';
import 'quiz_review_screen.dart';

List<String> _buildOptions(
    List<Map<String, String>> allItems, Map<String, String> current) {
  final correct = current['answer']!;
  final pool = allItems
      .map((i) => i['answer']!)
      .where((a) => a != correct)
      .toList()
    ..shuffle();
  return ([...pool.take(3), correct]..shuffle());
}

// ─── Main quiz list screen ────────────────────────────────────────────────────

class QuizScreen extends StatefulWidget {
  final List<Map<String, String>> items;
  final String mode;
  final String modeTitle;
  final Color accentColor;

  const QuizScreen({
    super.key,
    required this.items,
    required this.mode,
    required this.modeTitle,
    required this.accentColor,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<int> _selectedIndices;
  late List<List<String>> _options;
  bool _submitting = false;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedIndices = List.filled(widget.items.length, -1);
    _options =
        widget.items.map((item) => _buildOptions(widget.items, item)).toList();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  int get _answeredCount => _selectedIndices.where((i) => i >= 0).length;
  bool get _allAnswered => _answeredCount == widget.items.length;

  Future<void> _submit() async {
    if (!_allAnswered) {
      final firstUnanswered = _selectedIndices.indexWhere((i) => i < 0);
      if (firstUnanswered >= 0) {
        _scrollCtrl.animateTo(
          firstUnanswered * 220.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppTheme.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'Please answer all ${widget.items.length} questions first.',
          style: GoogleFonts.inter(color: AppTheme.textPrimary),
        ),
      ));
      return;
    }

    setState(() => _submitting = true);
    HapticFeedback.mediumImpact();

    final questions = List.generate(widget.items.length, (i) {
      final item = widget.items[i];
      final opts = _options[i];
      final chosen = _selectedIndices[i] >= 0 ? opts[_selectedIndices[i]] : '';
      return QuizQuestion(
        question: item['question']!,
        correctAnswer: item['answer']!,
        chosenAnswer: chosen,
        options: opts,
        type: item['type'] ?? 'word',
      );
    });

    final correct = questions.where((q) => q.isCorrect).length;
    final attempt = QuizAttempt(
      id: '',
      mode: widget.mode,
      modeTitle: widget.modeTitle,
      totalQuestions: widget.items.length,
      correctCount: correct,
      completedAt: DateTime.now(),
      questions: questions,
    );

    try {
      await context.read<AppProvider>().saveQuizAttempt(attempt);
    } catch (_) {}

    if (!mounted) return;
    setState(() => _submitting = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          attempt: attempt,
          accentColor: widget.accentColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _QuizHeader(
              modeTitle: widget.modeTitle,
              accentColor: widget.accentColor,
              answered: _answeredCount,
              total: widget.items.length,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _answeredCount / widget.items.length,
                  minHeight: 6,
                  backgroundColor: AppTheme.card,
                  valueColor: AlwaysStoppedAnimation(widget.accentColor),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                itemCount: widget.items.length,
                itemBuilder: (context, qi) => _QuestionCard(
                  index: qi,
                  item: widget.items[qi],
                  options: _options[qi],
                  selectedIndex: _selectedIndices[qi],
                  accentColor: widget.accentColor,
                  onSelect: (optIdx) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedIndices[qi] = optIdx);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            24, 12, 24, MediaQuery.of(context).padding.bottom + 12),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$_answeredCount / ${widget.items.length} answered',
                      style: GoogleFonts.inter(
                        color: _allAnswered
                            ? AppTheme.accent
                            : AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    _allAnswered ? 'Ready to submit!' : 'Answer all questions',
                    style: GoogleFonts.spaceGrotesk(
                      color: _allAnswered
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _allAnswered ? widget.accentColor : AppTheme.border,
                foregroundColor: AppTheme.bg,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Submit Quiz',
                      style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizHeader extends StatelessWidget {
  final String modeTitle;
  final Color accentColor;
  final int answered;
  final int total;
  const _QuizHeader(
      {required this.modeTitle,
      required this.accentColor,
      required this.answered,
      required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppTheme.card,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                title: Text('Exit Quiz?',
                    style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700)),
                content: Text('Your progress will not be saved.',
                    style: GoogleFonts.inter(
                        color: AppTheme.textSecondary, fontSize: 14)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Keep going',
                          style: TextStyle(color: AppTheme.accent))),
                  TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: const Text('Exit',
                          style: TextStyle(color: AppTheme.rose))),
                ],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border)),
              child: const Icon(Icons.close,
                  color: AppTheme.textSecondary, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(modeTitle,
                    style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                Text('$total questions',
                    style: GoogleFonts.inter(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: accentColor.withOpacity(0.3), width: 1),
            ),
            child: Text('$answered/$total',
                style: GoogleFonts.spaceGrotesk(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final Map<String, String> item;
  final List<String> options;
  final int selectedIndex;
  final Color accentColor;
  final ValueChanged<int> onSelect;

  const _QuestionCard({
    required this.index,
    required this.item,
    required this.options,
    required this.selectedIndex,
    required this.accentColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isAnswered = selectedIndex >= 0;
    final letters = ['A', 'B', 'C', 'D'];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAnswered
              ? accentColor.withOpacity(0.4)
              : AppTheme.border,
          width: isAnswered ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isAnswered
                        ? accentColor.withOpacity(0.15)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                        color: isAnswered
                            ? accentColor.withOpacity(0.4)
                            : AppTheme.border),
                  ),
                  child: Center(
                    child: Text('${index + 1}',
                        style: GoogleFonts.spaceGrotesk(
                            color: isAnswered
                                ? accentColor
                                : AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['type'] == 'word' ? 'WORD' : 'IDIOM',
                              style: GoogleFonts.spaceGrotesk(
                                  color: accentColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(item['question']!,
                          style: GoogleFonts.spaceGrotesk(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              height: 1.25)),
                      const SizedBox(height: 3),
                      Text('What does this mean?',
                          style: GoogleFonts.inter(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                if (isAnswered)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(Icons.check_circle,
                        color: accentColor, size: 20),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(options.length, (oi) {
            final isSelected = selectedIndex == oi;
            return GestureDetector(
              onTap: () => onSelect(oi),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withOpacity(0.1)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isSelected ? accentColor : AppTheme.border,
                      width: isSelected ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accentColor
                            : AppTheme.border.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Center(
                        child: Text(letters[oi],
                            style: GoogleFonts.spaceGrotesk(
                                color: isSelected
                                    ? AppTheme.bg
                                    : AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(options[oi],
                          style: GoogleFonts.inter(
                              color: isSelected
                                  ? accentColor
                                  : AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400)),
                    ),
                    if (isSelected)
                      Icon(Icons.radio_button_checked,
                          color: accentColor, size: 16),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
