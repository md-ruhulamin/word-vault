// lib/widgets/word_form_sheet.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vocab_store/app_provider.dart';
import 'package:vocab_store/app_theme.dart';
import 'package:vocab_store/tts_service.dart';
import 'package:vocab_store/model/word.dart';

class WordFormSheet extends StatefulWidget {
  final Word? word;
  const WordFormSheet({super.key, this.word});

  @override
  State<WordFormSheet> createState() => _WordFormSheetState();
}

class _WordFormSheetState extends State<WordFormSheet> {
  late TextEditingController _wordCtrl;
  late TextEditingController _meaningCtrl;
  late TextEditingController _sentenceCtrl;
  late TextEditingController _pronunciationCtrl;
  late TextEditingController _synonymInputCtrl;
  late TextEditingController _antonymInputCtrl;

  late List<String> _synonyms;
  late List<String> _antonyms;
  bool _loading = false;

  bool get _isEditing => widget.word != null;

  @override
  void initState() {
    super.initState();
    final w = widget.word;
    _wordCtrl = TextEditingController(text: w?.word ?? '');
    _meaningCtrl = TextEditingController(text: w?.meaning ?? '');
    _sentenceCtrl = TextEditingController(text: w?.sentence ?? '');
    _pronunciationCtrl = TextEditingController(text: w?.pronunciation ?? '');
    _synonymInputCtrl = TextEditingController();
    _antonymInputCtrl = TextEditingController();
    _synonyms = List.from(w?.synonyms ?? []);
    _antonyms = List.from(w?.antonyms ?? []);
  }

  @override
  void dispose() {
    _wordCtrl.dispose();
    _meaningCtrl.dispose();
    _sentenceCtrl.dispose();
    _pronunciationCtrl.dispose();
    _synonymInputCtrl.dispose();
    _antonymInputCtrl.dispose();
    super.dispose();
  }

  void _addTag(TextEditingController ctrl, List<String> list) {
    final val = ctrl.text.trim();
    if (val.isEmpty) return;
    // Support comma-separated input
    final parts = val.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
    setState(() {
      for (final part in parts) {
        if (!list.contains(part)) list.add(part);
      }
    });
    ctrl.clear();
  }

  void _removeTag(List<String> list, String tag) =>
      setState(() => list.remove(tag));

  Future<void> _save() async {
    if (_wordCtrl.text.trim().isEmpty || _meaningCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final provider = context.read<AppProvider>();
    final pron = _pronunciationCtrl.text.trim();

    if (_isEditing) {
      await provider.updateWord(widget.word!.copyWith(
        word: _wordCtrl.text.trim(),
        meaning: _meaningCtrl.text.trim(),
        sentence: _sentenceCtrl.text.trim(),
        synonyms: _synonyms,
        antonyms: _antonyms,
        pronunciation: pron.isEmpty ? null : pron,
        clearPronunciation: pron.isEmpty,
      ));
    } else {
      await provider.addWord(Word(
        id: '',
        word: _wordCtrl.text.trim(),
        meaning: _meaningCtrl.text.trim(),
        sentence: _sentenceCtrl.text.trim(),
        synonyms: _synonyms,
        antonyms: _antonyms,
        pronunciation: pron.isEmpty ? null : pron,
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
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              _isEditing ? 'Edit Word' : 'Add New Word',
              style: GoogleFonts.spaceGrotesk(
                color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text('Required fields marked *',
                style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 20),

            // ── Required ──────────────────────────────────────────────────────
            _sectionLabel('WORD & MEANING'),
            const SizedBox(height: 10),

            // Word + preview pronunciation button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Field(controller: _wordCtrl, label: 'Word *', hint: 'e.g. Ephemeral')),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _SpeakBtn(
                    onTap: () {
                      final tts = context.read<TtsService>();
                      tts.speakWord(
                        _wordCtrl.text.trim(),
                        pronunciation: _pronunciationCtrl.text.trim(),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Field(controller: _meaningCtrl, label: 'Meaning *', hint: 'e.g. Lasting for a very short time', maxLines: 3),
            const SizedBox(height: 12),
            _Field(controller: _sentenceCtrl, label: 'Example Sentence', hint: 'e.g. The ephemeral beauty of cherry blossoms.', maxLines: 2),

            const SizedBox(height: 20),

            // ── Optional ──────────────────────────────────────────────────────
            _sectionLabel('OPTIONAL'),
            const SizedBox(height: 10),

            // Pronunciation
            _Field(
              controller: _pronunciationCtrl,
              label: 'Pronunciation Guide',
              hint: 'e.g. ih-FEM-er-ul',
              suffixIcon: Icons.record_voice_over_outlined,
            ),
            const SizedBox(height: 4),
            Text('  How it sounds phonetically (shown on flashcard)',
                style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),

            const SizedBox(height: 16),

            // Synonyms
            _TagSection(
              label: 'Synonyms',
              color: AppTheme.accent,
              icon: Icons.add_circle_outline,
              tags: _synonyms,
              controller: _synonymInputCtrl,
              hint: 'e.g. fleeting, transient (press Enter or comma)',
              onAdd: () => _addTag(_synonymInputCtrl, _synonyms),
              onRemove: (tag) => _removeTag(_synonyms, tag),
            ),

            const SizedBox(height: 16),

            // Antonyms
            _TagSection(
              label: 'Antonyms',
              color: AppTheme.rose,
              icon: Icons.remove_circle_outline,
              tags: _antonyms,
              controller: _antonymInputCtrl,
              hint: 'e.g. eternal, permanent (press Enter or comma)',
              onAdd: () => _addTag(_antonymInputCtrl, _antonyms),
              onRemove: (tag) => _removeTag(_antonyms, tag),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.bg))
                    : Text(_isEditing ? 'Update Word' : 'Save Word'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Row(
    children: [
      Container(width: 3, height: 14, decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(text,
          style: GoogleFonts.spaceGrotesk(
            color: AppTheme.textSecondary, fontSize: 11,
            fontWeight: FontWeight.w700, letterSpacing: 1.5,
          )),
    ],
  );
}

// ─── Tag input section ────────────────────────────────────────────────────────

class _TagSection extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final List<String> tags;
  final TextEditingController controller;
  final String hint;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  const _TagSection({
    required this.label,
    required this.color,
    required this.icon,
    required this.tags,
    required this.controller,
    required this.hint,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.spaceGrotesk(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600,
                )),
            if (tags.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${tags.length}',
                    style: GoogleFonts.spaceGrotesk(
                        color: color, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        // Chips
        if (tags.isNotEmpty)
          Wrap(
            spacing: 6, runSpacing: 6,
            children: tags.map((tag) => _Chip(tag: tag, color: color, onRemove: () => onRemove(tag))).toList(),
          ),
        const SizedBox(height: 8),

        // Input row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onAdd(),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: color, width: 1.5),
                  ),
                  fillColor: AppTheme.card,
                  filled: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(Icons.add, color: color, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String tag;
  final Color color;
  final VoidCallback onRemove;
  const _Chip({required this.tag, required this.color, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tag,
              style: GoogleFonts.inter(
                  color: color, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, color: color, size: 14),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final IconData? suffixIcon;
  const _Field({
    required this.controller, required this.label, required this.hint,
    this.maxLines = 1, this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: AppTheme.textSecondary, size: 18)
            : null,
      ),
    );
  }
}

class _SpeakBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _SpeakBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tts = context.watch<TtsService>();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: tts.isSpeaking
              ? AppTheme.accent.withOpacity(0.2)
              : AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tts.isSpeaking ? AppTheme.accent : AppTheme.border,
          ),
        ),
        child: Icon(
          tts.isSpeaking ? Icons.stop_rounded : Icons.volume_up_outlined,
          color: tts.isSpeaking ? AppTheme.accent : AppTheme.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}
