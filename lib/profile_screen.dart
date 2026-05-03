// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vocab_store/app_provider.dart';
import 'package:vocab_store/app_theme.dart';
import 'package:vocab_store/firebase_service.dart';
import 'package:vocab_store/quiz_attempt.dart';
import 'quiz_review_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final fb = FirebaseService();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5C3), Color(0xFF00A3FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          '📚',
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Profile',
                              style: GoogleFonts.spaceGrotesk(
                                color: AppTheme.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              )),
                          Text('WordVault learner',
                              style: GoogleFonts.inter(
                                  color: AppTheme.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _confirmSignOut(context, fb),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Icon(Icons.logout,
                            color: AppTheme.textSecondary, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Vocabulary stats ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Text('Vocabulary',
                    style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Row(
                  children: [
                    _VocabCard(
                        icon: Icons.menu_book,
                        label: 'Words',
                        value: '${provider.words.length}',
                        color: AppTheme.accent),
                    const SizedBox(width: 10),
                    _VocabCard(
                        icon: Icons.format_quote,
                        label: 'Idioms',
                        value: '${provider.idioms.length}',
                        color: AppTheme.gold),
                    const SizedBox(width: 10),
                    _VocabCard(
                        icon: Icons.bookmark,
                        label: 'Saved',
                        value:
                            '${provider.bookmarkedWords.length + provider.bookmarkedIdioms.length}',
                        color: AppTheme.rose),
                  ],
                ),
              ),
            ),

            // ── Quiz stats ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                child: Text('Quiz Statistics',
                    style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _QuizStatsGrid(provider: provider),
              ),
            ),

            // ── History header ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: AppTheme.accent, size: 20),
                    const SizedBox(width: 8),
                    Text('Quiz History',
                        style: GoogleFonts.spaceGrotesk(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('${provider.attempts.length} attempts',
                        style: GoogleFonts.inter(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ),

            // ── Attempt list ──────────────────────────────────────────────────
            if (provider.attempts.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.quiz_outlined,
                            color: AppTheme.textSecondary, size: 40),
                        const SizedBox(height: 12),
                        Text('No quizzes taken yet',
                            style: GoogleFonts.spaceGrotesk(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Complete a quiz to see your history here.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final attempt = provider.attempts[i];
                    return Padding(
                      padding:
                          const EdgeInsets.fromLTRB(24, 0, 24, 10),
                      child: _AttemptCard(
                        attempt: attempt,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AttemptDetailScreen(attempt: attempt),
                          ),
                        ),
                        onDelete: () =>
                            provider.deleteAttempt(attempt.id),
                      ),
                    );
                  },
                  childCount: provider.attempts.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, FirebaseService fb) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Sign Out?',
            style: GoogleFonts.spaceGrotesk(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('You can sign back in anytime.',
            style:
                GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              fb.signOut();
            },
            child: const Text('Sign Out',
                style: TextStyle(color: AppTheme.rose)),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _VocabCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _VocabCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: color.withOpacity(0.25), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            Text(label,
                style: GoogleFonts.inter(
                    color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _QuizStatsGrid extends StatelessWidget {
  final AppProvider provider;
  const _QuizStatsGrid({required this.provider});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatItem(
          label: 'Quizzes Taken',
          value: '${provider.totalQuizzesTaken}',
          icon: Icons.quiz,
          color: AppTheme.accent),
      _StatItem(
          label: 'Avg Score',
          value: '${provider.averageScore.round()}%',
          icon: Icons.trending_up,
          color: AppTheme.gold),
      _StatItem(
          label: 'Best Score',
          value: '${provider.bestScore}%',
          icon: Icons.emoji_events,
          color: const Color(0xFF9D78F5)),
      _StatItem(
          label: 'Total Correct',
          value: '${provider.totalCorrect}',
          icon: Icons.check_circle,
          color: AppTheme.accent),
      _StatItem(
          label: 'Total Answered',
          value: '${provider.totalQuestionsAnswered}',
          icon: Icons.help_outline,
          color: AppTheme.textSecondary),
      _StatItem(
          label: 'Accuracy',
          value: provider.totalQuestionsAnswered > 0
              ? '${(provider.totalCorrect / provider.totalQuestionsAnswered * 100).round()}%'
              : '-',
          icon: Icons.percent,
          color: AppTheme.rose),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: stats.length,
      itemBuilder: (context, i) => _StatGridCell(stat: stats[i]),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
}

class _StatGridCell extends StatelessWidget {
  final _StatItem stat;
  const _StatGridCell({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(stat.icon, color: stat.color, size: 20),
          const SizedBox(height: 6),
          Text(stat.value,
              style: GoogleFonts.spaceGrotesk(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(stat.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: AppTheme.textSecondary, fontSize: 9)),
        ],
      ),
    );
  }
}

class _AttemptCard extends StatelessWidget {
  final QuizAttempt attempt;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AttemptCard({
    required this.attempt,
    required this.onTap,
    required this.onDelete,
  });

  Color get _modeColor {
    switch (attempt.mode) {
      case 'words': return AppTheme.accent;
      case 'bookmarked': return AppTheme.gold;
      case 'idioms': return const Color(0xFF9D78F5);
      case 'mixed': return AppTheme.rose;
      default: return AppTheme.accent;
    }
  }

  String get _timeAgo {
    final now = DateTime.now();
    final diff = now.difference(attempt.completedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[attempt.completedAt.month - 1]} ${attempt.completedAt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _modeColor;
    final pct = attempt.percentage;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            // Score circle
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
                border: Border.all(color: color.withOpacity(0.4), width: 2),
              ),
              child: Center(
                child: Text(attempt.grade,
                    style: GoogleFonts.spaceGrotesk(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(attempt.modeTitle,
                      style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text('$pct%  •  ',
                          style: GoogleFonts.inter(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      Text(
                          '${attempt.correctCount}/${attempt.totalQuestions} correct',
                          style: GoogleFonts.inter(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Mini score bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: AppTheme.surface,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Time + delete
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_timeAgo,
                    style: GoogleFonts.inter(
                        color: AppTheme.textSecondary, fontSize: 11)),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onTap,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Icon(Icons.visibility_outlined,
                            color: color, size: 14),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _confirmDelete(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.rose.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(Icons.delete_outline,
                            color: AppTheme.rose, size: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete attempt?',
            style: GoogleFonts.spaceGrotesk(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('This cannot be undone.',
            style:
                GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.rose)),
          ),
        ],
      ),
    );
  }
}
