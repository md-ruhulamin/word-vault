// lib/screens/idioms_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vocab_store/app_provider.dart';
import 'package:vocab_store/app_theme.dart';
import 'package:vocab_store/model/idiom.dart';
import 'package:vocab_store/tts_service.dart';

class IdiomsScreen extends StatefulWidget {
  const IdiomsScreen({super.key});

  @override
  State<IdiomsScreen> createState() => _IdiomsScreenState();
}

class _IdiomsScreenState extends State<IdiomsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final filtered = provider.idioms
        .where((i) =>
            i.phrase.toLowerCase().contains(_search.toLowerCase()) ||
            i.meaning.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Idioms & Phrases',
                            style: GoogleFonts.spaceGrotesk(
                              color: AppTheme.textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            )),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Search idioms...',
                  prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.format_quote_outlined,
                              color: AppTheme.textSecondary, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            _search.isEmpty
                                ? 'No idioms yet.\nTap + to add one!'
                                : 'No results for "$_search"',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                color: AppTheme.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        return _IdiomCard(
                          idiom: filtered[i],
                          onEdit: () => _showForm(context, idiom: filtered[i]),
                          onDelete: () =>
                              _confirmDelete(context, filtered[i].id),
                          onBookmark: () =>
                              provider.toggleIdiomBookmark(filtered[i]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showForm(BuildContext context, {Idiom? idiom}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IdiomFormSheet(idiom: idiom),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Delete Idiom',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Are you sure?',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () {
              context.read<AppProvider>().deleteIdiom(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.rose)),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.gold,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.add, color: AppTheme.bg, size: 22),
      ),
    );
  }
}

class _IdiomCard extends StatefulWidget {
  final Idiom idiom;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onBookmark;

  const _IdiomCard({
    required this.idiom,
    required this.onEdit,
    required this.onDelete,
    required this.onBookmark,
  });

  @override
  State<_IdiomCard> createState() => _IdiomCardState();
}

class _IdiomCardState extends State<_IdiomCard> {
  bool _isExpanded = false;

  // Capitalise first letter
  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final tts = context.read<TtsService>();
    final idiom = widget.idiom;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: idiom.isBookmarked
              ? AppTheme.gold.withOpacity(0.45)
              : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            // ── Zero gap between speaker and phrase ───────────────────────
            minLeadingWidth: 0,
            horizontalTitleGap: 5,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 2),

            // Speaker — taps to speak the phrase
            leading: GestureDetector(
              onTap: () => tts.speakWord(
                idiom.phrase,
              ),
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.volume_up_outlined,
                    color: AppTheme.gold, size: 16),
              ),
            ),

            // Phrase — first letter capitalised, size 16
            title: Text(
              _cap(idiom.phrase),
              style: GoogleFonts.spaceGrotesk(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),

            // Meaning — tappable, small speaker hint on the right
            subtitle: GestureDetector(
              onTap: () => tts.speak(idiom.meaning),
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _cap(idiom.meaning),
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.volume_up_outlined,
                        size: 18,
                        color: AppTheme.textSecondary.withOpacity(0.35)),
                  ],
                ),
              ),
            ),

            // Expand / collapse
            trailing: GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ),
          ),

          // ── Expanded section ──────────────────────────────────────────────
          if (_isExpanded) ...[
            // Example sentence — tappable, spoken slowly
            if (idiom.example.isNotEmpty)
              GestureDetector(
                onTap: () => tts.speakSlow(idiom.example),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.format_quote,
                            color: AppTheme.gold, size: 13),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _cap(idiom.example),
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.volume_up_outlined,
                            size: 11,
                            color: AppTheme.textSecondary.withOpacity(0.35)),
                      ],
                    ),
                  ),
                ),
              ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _ActionBtn(
                    icon: idiom.isBookmarked
                        ? Icons.bookmark
                        : Icons.bookmark_outline,
                    color: idiom.isBookmarked
                        ? AppTheme.gold
                        : AppTheme.textSecondary,
                    onTap: widget.onBookmark,
                  ),
                  const SizedBox(width: 8),
                  _ActionBtn(
                      icon: Icons.edit_outlined,
                      color: AppTheme.accent,
                      onTap: widget.onEdit),
                  const SizedBox(width: 8),
                  _ActionBtn(
                      icon: Icons.delete_outline,
                      color: AppTheme.rose,
                      onTap: widget.onDelete),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      );
}

// ── Idiom Form Sheet ──────────────────────────────────────────────────────────

class _IdiomFormSheet extends StatefulWidget {
  final Idiom? idiom;
  const _IdiomFormSheet({this.idiom});

  @override
  State<_IdiomFormSheet> createState() => _IdiomFormSheetState();
}

class _IdiomFormSheetState extends State<_IdiomFormSheet> {
  late TextEditingController _phraseCtrl;
  late TextEditingController _meaningCtrl;
  late TextEditingController _exampleCtrl;
  bool _loading = false;

  bool get _isEditing => widget.idiom != null;

  @override
  void initState() {
    super.initState();
    _phraseCtrl = TextEditingController(text: widget.idiom?.phrase ?? '');
    _meaningCtrl = TextEditingController(text: widget.idiom?.meaning ?? '');
    _exampleCtrl = TextEditingController(text: widget.idiom?.example ?? '');
  }

  @override
  void dispose() {
    _phraseCtrl.dispose();
    _meaningCtrl.dispose();
    _exampleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_phraseCtrl.text.trim().isEmpty || _meaningCtrl.text.trim().isEmpty)
      return;
    setState(() => _loading = true);
    final provider = context.read<AppProvider>();
    if (_isEditing) {
      await provider.updateIdiom(widget.idiom!.copyWith(
        phrase: _phraseCtrl.text.trim(),
        meaning: _meaningCtrl.text.trim(),
        example: _exampleCtrl.text.trim(),
      ));
    } else {
      await provider.addIdiom(Idiom(
        id: '',
        phrase: _phraseCtrl.text.trim(),
        meaning: _meaningCtrl.text.trim(),
        example: _exampleCtrl.text.trim(),
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isEditing ? 'Edit Idiom' : 'Add Idiom / Phrase',
              style: GoogleFonts.spaceGrotesk(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            _tf(_phraseCtrl, 'Phrase *', 'e.g. Break a leg'),
            const SizedBox(height: 14),
            _tf(_meaningCtrl, 'Meaning *', 'e.g. Good luck', maxLines: 3),
            const SizedBox(height: 14),
            _tf(_exampleCtrl, 'Example', 'e.g. Break a leg in your interview!',
                maxLines: 2),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: AppTheme.bg),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.bg))
                    : Text(_isEditing ? 'Update' : 'Save Idiom'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tf(TextEditingController c, String label, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}
