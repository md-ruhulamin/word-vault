// lib/screens/words_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vocab_store/app_provider.dart';
import 'package:vocab_store/app_theme.dart';
import 'package:vocab_store/tts_service.dart';
import 'package:vocab_store/model/word.dart';
import 'word_form_sheet.dart';

class WordsScreen extends StatefulWidget {
  const WordsScreen({super.key});

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    // ── Read TtsService HERE, at the screen level where the provider IS in scope.
    // Then pass it down to _WordCard as a plain parameter — no provider.watch()
    // call needed inside the card itself.
    final tts = context.read<TtsService>();

    final filtered = provider.words
        .where((w) =>
            w.word.toLowerCase().contains(_search.toLowerCase()) ||
            w.meaning.toLowerCase().contains(_search.toLowerCase()) ||
            w.synonyms
                .any((s) => s.toLowerCase().contains(_search.toLowerCase())) ||
            w.antonyms
                .any((a) => a.toLowerCase().contains(_search.toLowerCase())))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Words',
                            style: GoogleFonts.spaceGrotesk(
                                color: AppTheme.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w700)),
                        Text('${filtered.length} entries',
                            style: GoogleFonts.inter(
                                color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  _AddButton(onTap: () => _showForm(context)),
                ],
              ),
            ),

            // ── Search ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Search words, synonyms, antonyms...',
                  prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── List ──────────────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.menu_book_outlined,
                              color: AppTheme.textSecondary, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            _search.isEmpty
                                ? 'No words yet.\nTap + to add your first word!'
                                : 'No results for "$_search"',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                color: AppTheme.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: filtered.length,
                      // Pass tts as a plain parameter — no context.watch inside card
                      itemBuilder: (context, i) => _WordCard(
                        word: filtered[i],
                        tts: tts,
                        onEdit: () => _showForm(context, word: filtered[i]),
                        onDelete: () => _confirmDelete(context, filtered[i].id),
                        onBookmark: () =>
                            provider.toggleWordBookmark(filtered[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showForm(BuildContext context, {Word? word}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WordFormSheet(word: word),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Delete Word',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Are you sure you want to delete this word?',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () {
              context.read<AppProvider>().deleteWord(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.rose)),
          ),
        ],
      ),
    );
  }
}

// ─── Add button ───────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: AppTheme.accent, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.add, color: AppTheme.bg, size: 22),
        ),
      );
}

// ─── Word Card ────────────────────────────────────────────────────────────────
// TtsService is passed in directly — NO context.watch<TtsService>() here.

class _WordCard extends StatelessWidget {
  final Word word;
  final TtsService tts; // ← passed from parent, not looked up in context
  final VoidCallback onEdit, onDelete, onBookmark;

  const _WordCard({
    required this.word,
    required this.tts,
    required this.onEdit,
    required this.onDelete,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: word.isBookmarked
              ? AppTheme.gold.withOpacity(0.4)
              : AppTheme.border,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        iconColor: AppTheme.textSecondary,
        collapsedIconColor: AppTheme.textSecondary,

        // ── Title row: speaker icon + word + pronunciation ─────────────
        title: Row(
          children: [
            GestureDetector(
              onTap: () =>
                  tts.speakWord(word.word,),
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.volume_up_outlined,
                    color: AppTheme.accent, size: 16),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(word.word,
                      style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  if (word.hasPronunciation)
                    Text(
                      '/${word.pronunciation}/',
                      style: GoogleFonts.inter(
                          color: AppTheme.accent.withOpacity(0.7),
                          fontSize: 11,
                          fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ),
          ],
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(left: 42),
          child: Text(word.meaning.split("(")[1].trim().split(")")[0].trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  color: AppTheme.textSecondary, fontSize: 13)),
        ),

        // ── Expanded body ─────────────────────────────────────────────────
        children: [
          // Full meaning
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(word.meaning.split("(")[0].trim(),
                style: GoogleFonts.inter(
                    color: AppTheme.textSecondary, fontSize: 13)),
          ),

          // Example sentence — tap to hear it read slowly
          if (word.sentence.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => tts.speakSlow(word.sentence),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.format_quote,
                        color: AppTheme.accent, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(word.sentence,
                          style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontStyle: FontStyle.italic)),
                    ),
                    const Icon(Icons.volume_up_outlined,
                        color: AppTheme.textSecondary, size: 14),
                  ],
                ),
              ),
            ),
          ],

          // Synonyms
          if (word.hasSynonyms) ...[
            const SizedBox(height: 10),
            _WordRelationRow(
              label: 'Synonyms',
              color: AppTheme.accent,
              icon: Icons.add_circle_outline,
              tags: word.synonyms,
              onTapTag: (t) => tts.speak(t),
            ),
          ],

          // Antonyms
          if (word.hasAntonyms) ...[
            const SizedBox(height: 8),
            _WordRelationRow(
              label: 'Antonyms',
              color: AppTheme.rose,
              icon: Icons.remove_circle_outline,
              tags: word.antonyms,
              onTapTag: (t) => tts.speak(t),
            ),
          ],

          const SizedBox(height: 14),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ActionBtn(
                icon:
                    word.isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                color:
                    word.isBookmarked ? AppTheme.gold : AppTheme.textSecondary,
                onTap: onBookmark,
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                  icon: Icons.edit_outlined,
                  color: AppTheme.accent,
                  onTap: onEdit),
              const SizedBox(width: 8),
              _ActionBtn(
                  icon: Icons.delete_outline,
                  color: AppTheme.rose,
                  onTap: onDelete),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Synonym / Antonym chip row ───────────────────────────────────────────────

class _WordRelationRow extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final List<String> tags;
  final ValueChanged<String> onTapTag;

  const _WordRelationRow({
    required this.label,
    required this.color,
    required this.icon,
    required this.tags,
    required this.onTapTag,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.spaceGrotesk(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 5,
          children: tags
              .map((t) => GestureDetector(
                    onTap: () => onTapTag(t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(t,
                              style: GoogleFonts.inter(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(width: 4),
                          Icon(Icons.volume_up_outlined,
                              color: color.withOpacity(0.6), size: 11),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ─── Action button ────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      );
}
