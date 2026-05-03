// lib/screens/bookmarks_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vocab_store/app_provider.dart';
import 'package:vocab_store/app_theme.dart';
import 'package:vocab_store/audio_view.dart';


class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final bWords = provider.bookmarkedWords;
    final bIdioms = provider.bookmarkedIdioms;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Row(
                children: [
                  const Icon(Icons.bookmark, color: AppTheme.gold, size: 28),
                  const SizedBox(width: 10),
                  Text('Saved',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ),
            TabBar(
              controller: _tab,
              indicatorColor: AppTheme.gold,
              labelColor: AppTheme.gold,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle:
                  GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: 'Words (${bWords.length})'),
                Tab(text: 'Idioms (${bIdioms.length})'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _BookmarkList(
                    items: bWords
                        .map((w) => _BookmarkItem(
                              title: w.word,
                              subtitle: w.meaning,
                              sentence: w.sentence,
                              color: AppTheme.accent,
                              icon: Icons.abc,
                              onRemove: () =>
                                  provider.toggleWordBookmark(w),
                            ))
                        .toList(),
                    emptyMessage: 'No bookmarked words yet.',
                  ),
                  _BookmarkList(
                    items: bIdioms
                        .map((i) => _BookmarkItem(
                              title: i.phrase,
                              subtitle: i.meaning,
                              sentence: i.example,
                              color: AppTheme.gold,
                              icon: Icons.format_quote,
                              onRemove: () =>
                                  provider.toggleIdiomBookmark(i),
                            ))
                        .toList(),
                    emptyMessage: 'No bookmarked idioms yet.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkList extends StatelessWidget {
  final List<_BookmarkItem> items;
  final String emptyMessage;
  const _BookmarkList(
      {required this.items, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_border,
                color: AppTheme.textSecondary, size: 48),
            const SizedBox(height: 12),
            Text(emptyMessage,
                style: GoogleFonts.inter(
                    color: AppTheme.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: items.length,
      itemBuilder: (context, i) => _BookmarkCard(item: items[i]),
    );
  }
}

class _BookmarkItem {
  final String title;
  final String subtitle;
  final String sentence;
  final Color color;
  final IconData icon;
  final VoidCallback onRemove;
  const _BookmarkItem({
    required this.title,
    required this.subtitle,
    required this.sentence,
    required this.color,
    required this.icon,
    required this.onRemove,
  });
}

class _BookmarkCard extends StatelessWidget {
  final _BookmarkItem item;
  const _BookmarkCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(item.title,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    )),
              ),
              SpeakTheWord(text: item.title),
              SizedBox(width: 8),
              GestureDetector(
                onTap: item.onRemove,
                child: const Icon(Icons.bookmark,
                    color: AppTheme.gold, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(item.subtitle,
              style: GoogleFonts.inter(
                  color: AppTheme.textSecondary, fontSize: 13)),
          if (item.sentence.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('"${item.sentence}"',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary.withOpacity(0.7),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                )),
          ],
        ],
      ),
    );
  }
}
