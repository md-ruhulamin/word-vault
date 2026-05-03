// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vocab_store/app_provider.dart';
import 'package:vocab_store/app_theme.dart';
import 'package:vocab_store/audio_view.dart';
import 'package:vocab_store/firebase_service.dart';
import 'package:vocab_store/profile_screen.dart';
import 'package:vocab_store/word_scramble_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final fb = FirebaseService();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('WordVault',
                              style: GoogleFonts.spaceGrotesk(
                                color: AppTheme.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              )),
                          const SizedBox(height: 4),
                          Text('Your Dashboard',
                              style: GoogleFonts.spaceGrotesk(
                                color: AppTheme.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              )),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WordScrambleScreen(),
                          )),
                      icon: const Icon(Icons.games,
                          size: 25, color: AppTheme.textSecondary),
                      tooltip: 'Game',
                    ),
                    SizedBox(width: 12),
                    IconButton(
                      onPressed: () => fb.signOut(),
                      icon: const Icon(Icons.logout,
                          color: AppTheme.textSecondary),
                      tooltip: 'Sign Out',
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: _StatsRow(provider: provider),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Text('Recent Words',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ),
            if (provider.words.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: _EmptyState(
                      icon: Icons.menu_book_outlined,
                      message: 'No words yet. Add your first word!'),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final word = provider.words[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 6),
                      child: _WordPreviewCard(
                        term: word.word,
                        meaning: word.meaning,
                        isBookmarked: word.isBookmarked,
                        type: 'word',
                        onBookmark: () => provider.toggleWordBookmark(word),
                      ),
                    );
                  },
                  childCount:
                      provider.words.length > 5 ? 5 : provider.words.length,
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Text('Recent Idioms & Phrases',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ),
            if (provider.idioms.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: _EmptyState(
                      icon: Icons.format_quote_outlined,
                      message: 'No idioms yet. Add one now!'),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final idiom = provider.idioms[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 6),
                      child: _WordPreviewCard(
                        term: idiom.phrase,
                        meaning: idiom.meaning,
                        isBookmarked: idiom.isBookmarked,
                        type: 'idiom',
                        onBookmark: () => provider.toggleIdiomBookmark(idiom),
                      ),
                    );
                  },
                  childCount:
                      provider.idioms.length > 5 ? 5 : provider.idioms.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AppProvider provider;
  const _StatsRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          value: '${provider.words.length}',
          label: 'Words',
          icon: Icons.menu_book,
          color: AppTheme.accent,
        ),
        const SizedBox(width: 12),
        _StatCard(
          value: '${provider.idioms.length}',
          label: 'Idioms',
          icon: Icons.format_quote,
          color: AppTheme.gold,
        ),
        const SizedBox(width: 12),
        _StatCard(
          value:
              '${provider.bookmarkedWords.length + provider.bookmarkedIdioms.length}',
          label: 'Saved',
          icon: Icons.bookmark,
          color: AppTheme.rose,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.spaceGrotesk(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                )),
            Text(label,
                style: GoogleFonts.inter(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _WordPreviewCard extends StatelessWidget {
  final String term;
  final String meaning;
  final bool isBookmarked;
  final String type;
  final VoidCallback onBookmark;
  const _WordPreviewCard({
    required this.term,
    required this.meaning,
    required this.isBookmarked,
    required this.type,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (type == 'word' ? AppTheme.accent : AppTheme.gold)
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              type == 'word' ? Icons.abc : Icons.format_quote,
              color: type == 'word' ? AppTheme.accent : AppTheme.gold,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(term[0].toUpperCase() + term.substring(1),
                        style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        )),
                    SpeakTheWord(
                      text: term,
                    ),
                  ],
                ),
                if (type == 'word')
                  Text(meaning.split("(")[1].trim().split(")")[0],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          color: AppTheme.textSecondary, fontSize: 12)),
                  if (type == 'idiom')
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(meaning,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              color: AppTheme.textSecondary, fontSize: 12)),)
              ],
            ),
          ),
          GestureDetector(
            onTap: onBookmark,
            child: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
              color: isBookmarked ? AppTheme.gold : AppTheme.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 36),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
