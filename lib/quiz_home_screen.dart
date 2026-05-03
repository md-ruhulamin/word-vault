// lib/screens/quiz_home_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vocab_store/app_provider.dart';
import 'package:vocab_store/app_theme.dart';

import 'quiz_screen.dart';

class QuizHomeScreen extends StatelessWidget {
  const QuizHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    final modes = [
      _QuizMode(
        id: 'words', title: 'My Words',
        subtitle: '${provider.words.length} words',
        icon: Icons.menu_book_rounded, color: AppTheme.accent,
        enabled: provider.words.isNotEmpty,
        description: 'Match each word to its meaning',
      ),
      _QuizMode(
        id: 'bookmarked', title: 'Bookmarked',
        subtitle: '${provider.bookmarkedWords.length + provider.bookmarkedIdioms.length} saved',
        icon: Icons.bookmark_rounded, color: AppTheme.gold,
        enabled: provider.bookmarkedWords.isNotEmpty || provider.bookmarkedIdioms.isNotEmpty,
        description: 'Quiz on your saved words & idioms',
      ),
      _QuizMode(
        id: 'idioms', title: 'Idioms & Phrases',
        subtitle: '${provider.idioms.length} idioms',
        icon: Icons.format_quote_rounded, color: const Color(0xFF9D78F5),
        enabled: provider.idioms.isNotEmpty,
        description: 'Match idioms to their meanings',
      ),
      _QuizMode(
        id: 'synonyms', title: 'Synonym Quiz',
        subtitle: '${provider.wordsWithSynonyms.length} words with synonyms',
        icon: Icons.compare_arrows_rounded, color: const Color(0xFF06D6A0),
        enabled: provider.wordsWithSynonyms.isNotEmpty,
        description: 'Find the correct synonym for each word',
        isNew: true,
      ),
      _QuizMode(
        id: 'antonyms', title: 'Antonym Quiz',
        subtitle: '${provider.wordsWithAntonyms.length} words with antonyms',
        icon: Icons.swap_horiz_rounded, color: const Color(0xFFFF9F1C),
        enabled: provider.wordsWithAntonyms.isNotEmpty,
        description: 'Find the opposite of each word',
        isNew: true,
      ),
      _QuizMode(
        id: 'mixed', title: 'Mixed Challenge',
        subtitle: 'Everything combined',
        icon: Icons.shuffle_rounded, color: AppTheme.rose,
        enabled: provider.words.isNotEmpty || provider.idioms.isNotEmpty,
        description: 'All words & idioms shuffled together',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quiz Mode',
                        style: GoogleFonts.spaceGrotesk(
                            color: AppTheme.textPrimary,
                            fontSize: 26, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Choose a category and test yourself',
                        style: GoogleFonts.inter(
                            color: AppTheme.textSecondary, fontSize: 13)),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: _QuizModeCard(
                    mode: modes[i],
                    onTap: modes[i].enabled ? () => _startQuiz(context, modes[i]) : null,
                  ),
                ),
                childCount: modes.length,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.18)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: AppTheme.accent, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Add synonyms & antonyms when creating a word to unlock Synonym and Antonym quiz modes.',
                          style: GoogleFonts.inter(color: AppTheme.accent, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startQuiz(BuildContext context, _QuizMode mode) {
    final provider = context.read<AppProvider>();
    final items = provider.getQuizItems(mode.id);

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppTheme.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text('Not enough items to start a quiz.',
            style: TextStyle(color: AppTheme.textPrimary)),
      ));
      return;
    }

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => QuizScreen(
        items: items, mode: mode.id,
        modeTitle: mode.title, accentColor: mode.color,
      ),
    ));
  }
}

class _QuizMode {
  final String id, title, subtitle, description;
  final IconData icon;
  final Color color;
  final bool enabled;
  final bool isNew;

  const _QuizMode({
    required this.id, required this.title, required this.subtitle,
    required this.icon, required this.color, required this.enabled,
    required this.description, this.isNew = false,
  });
}

class _QuizModeCard extends StatelessWidget {
  final _QuizMode mode;
  final VoidCallback? onTap;
  const _QuizModeCard({required this.mode, this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: active ? AppTheme.card : AppTheme.card.withOpacity(0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? mode.color.withOpacity(0.4) : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: mode.color.withOpacity(active ? 0.15 : 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(mode.icon,
                  color: active ? mode.color : mode.color.withOpacity(0.3), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(mode.title,
                          style: GoogleFonts.spaceGrotesk(
                              color: active ? AppTheme.textPrimary : AppTheme.textSecondary,
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      if (mode.isNew) ...[
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: mode.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('NEW',
                              style: GoogleFonts.spaceGrotesk(
                                  color: mode.color, fontSize: 9, fontWeight: FontWeight.w800,
                                  letterSpacing: 1)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(mode.description,
                      style: GoogleFonts.inter(
                          color: active
                              ? AppTheme.textSecondary
                              : AppTheme.textSecondary.withOpacity(0.5),
                          fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    active ? mode.subtitle : '${mode.subtitle} — add more to unlock',
                    style: GoogleFonts.inter(
                      color: active ? mode.color.withOpacity(0.8) : AppTheme.textSecondary.withOpacity(0.4),
                      fontSize: 11, fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 13, color: active ? AppTheme.textSecondary : AppTheme.border),
          ],
        ),
      ),
    );
  }
}
