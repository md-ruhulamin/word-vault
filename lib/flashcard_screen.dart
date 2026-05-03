// lib/screens/flashcard_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vocab_store/app_provider.dart';
import 'package:vocab_store/app_theme.dart';
import 'package:vocab_store/tts_service.dart';

// ─── Card type: what to show on front/back ────────────────────────────────────

enum FlashCardMode { meaningOnly, withSynonyms, withAntonyms, fullWord }

class FlashItem {
  final String front;       // word / phrase
  final String back;        // meaning
  final String? example;
  final String type;        // 'word' | 'idiom'
  final List<String> synonyms;
  final List<String> antonyms;
  final String? pronunciation;

  const FlashItem({
    required this.front, required this.back,
    this.example, required this.type,
    this.synonyms = const [], this.antonyms = const [],
    this.pronunciation,
  });

  bool get hasSynonyms => synonyms.isNotEmpty;
  bool get hasAntonyms => antonyms.isNotEmpty;
}

// ─── Mode selector home ───────────────────────────────────────────────────────

class FlashcardHomeScreen extends StatelessWidget {
  const FlashcardHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    final modes = [
      _FlashMode(
        id: 'words', title: 'My Words',
        subtitle: '${provider.words.length} cards',
        icon: Icons.menu_book_rounded, color: AppTheme.accent,
        enabled: provider.words.isNotEmpty,
        items: provider.words.map((w) => FlashItem(
          front: w.word, back: w.meaning,
          example: w.sentence.isNotEmpty ? w.sentence : null,
          type: 'word', synonyms: w.synonyms, antonyms: w.antonyms,
          pronunciation: w.pronunciation,
        )).toList(),
      ),
      _FlashMode(
        id: 'bookmarked_words', title: 'Saved Words',
        subtitle: '${provider.bookmarkedWords.length} saved',
        icon: Icons.bookmark_rounded, color: AppTheme.gold,
        enabled: provider.bookmarkedWords.isNotEmpty,
        items: provider.bookmarkedWords.map((w) => FlashItem(
          front: w.word, back: w.meaning,
          example: w.sentence.isNotEmpty ? w.sentence : null,
          type: 'word', synonyms: w.synonyms, antonyms: w.antonyms,
          pronunciation: w.pronunciation,
        )).toList(),
      ),
      _FlashMode(
        id: 'idioms', title: 'Idioms & Phrases',
        subtitle: '${provider.idioms.length} cards',
        icon: Icons.format_quote_rounded, color: const Color(0xFF9D78F5),
        enabled: provider.idioms.isNotEmpty,
        items: provider.idioms.map((i) => FlashItem(
          front: i.phrase, back: i.meaning,
          example: i.example.isNotEmpty ? i.example : null,
          type: 'idiom',
        )).toList(),
      ),
      _FlashMode(
        id: 'bookmarked_idioms', title: 'Saved Idioms',
        subtitle: '${provider.bookmarkedIdioms.length} saved',
        icon: Icons.stars_rounded, color: AppTheme.rose,
        enabled: provider.bookmarkedIdioms.isNotEmpty,
        items: provider.bookmarkedIdioms.map((i) => FlashItem(
          front: i.phrase, back: i.meaning,
          example: i.example.isNotEmpty ? i.example : null,
          type: 'idiom',
        )).toList(),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5C3), Color(0xFF00A3FF)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.style_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Flashcards',
                                style: GoogleFonts.spaceGrotesk(
                                    color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
                            Text('Tap to flip • Swipe to navigate',
                                style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                  child: _ModeCard(
                    mode: modes[i],
                    onTap: modes[i].enabled
                        ? () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => FlashcardDeckScreen(
                                items: modes[i].items,
                                title: modes[i].title,
                                accentColor: modes[i].color,
                              ),
                            ))
                        : null,
                  ),
                ),
                childCount: modes.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _FlashMode {
  final String id, title, subtitle;
  final IconData icon;
  final Color color;
  final bool enabled;
  final List<FlashItem> items;
  const _FlashMode({
    required this.id, required this.title, required this.subtitle,
    required this.icon, required this.color, required this.enabled,
    required this.items,
  });
}

class _ModeCard extends StatelessWidget {
  final _FlashMode mode;
  final VoidCallback? onTap;
  const _ModeCard({required this.mode, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: onTap != null ? AppTheme.card : AppTheme.card.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: onTap != null ? mode.color.withOpacity(0.35) : AppTheme.border, width: 1.5),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 52, height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.translate(
                    offset: const Offset(4, 4),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: mode.color.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: mode.color.withOpacity(0.2)),
                      ),
                    ),
                  ),
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: mode.color.withOpacity(onTap != null ? 0.15 : 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: mode.color.withOpacity(onTap != null ? 0.4 : 0.15)),
                    ),
                    child: Icon(mode.icon,
                        color: onTap != null ? mode.color : mode.color.withOpacity(0.3), size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mode.title,
                      style: GoogleFonts.spaceGrotesk(
                          color: onTap != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(onTap != null ? mode.subtitle : 'Add items to unlock',
                      style: GoogleFonts.inter(
                          color: onTap != null
                              ? AppTheme.textSecondary
                              : AppTheme.textSecondary.withOpacity(0.4),
                          fontSize: 12)),
                ],
              ),
            ),
            if (onTap != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: mode.color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text('Study',
                    style: GoogleFonts.spaceGrotesk(
                        color: mode.color, fontSize: 12, fontWeight: FontWeight.w600)),
              )
            else
              Icon(Icons.lock_outline, color: AppTheme.border, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Deck screen ──────────────────────────────────────────────────────────────

class FlashcardDeckScreen extends StatefulWidget {
  final List<FlashItem> items;
  final String title;
  final Color accentColor;

  const FlashcardDeckScreen({
    super.key, required this.items, required this.title, required this.accentColor,
  });

  @override
  State<FlashcardDeckScreen> createState() => _FlashcardDeckScreenState();
}

class _FlashcardDeckScreenState extends State<FlashcardDeckScreen>
    with TickerProviderStateMixin {
  late List<FlashItem> _items;
  int _currentIndex = 0;

  // Which face is showing: 0 = word, 1 = meaning, 2 = synonyms, 3 = antonyms
  int _face = 0;

  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  // Available faces for the current card
  List<int> get _availableFaces {
    final item = _items[_currentIndex];
    final faces = [0, 1]; // always: word + meaning
    if (item.hasSynonyms) faces.add(2);
    if (item.hasAntonyms) faces.add(3);
    return faces;
  }

  int get _faceCount => _availableFaces.length;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items)..shuffle();
    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _flipAnim = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: pi / 2).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: -pi / 2, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
    ]).animate(_flipCtrl);
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slideAnim = Tween<Offset>(begin: Offset.zero, end: const Offset(-1.5, 0))
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeInCubic));
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_flipCtrl.isAnimating) return;
    HapticFeedback.lightImpact();
    final nextFace = (_face + 1) % _faceCount;
    setState(() => _face = nextFace);
    _flipCtrl.forward(from: 0);
  }

  void _next() {
    if (_currentIndex >= _items.length - 1) return;
    HapticFeedback.selectionClick();
    _slideCtrl.forward(from: 0).then((_) {
      setState(() { _currentIndex++; _face = 0; });
      _slideCtrl.reset();
    });
  }

  void _prev() {
    if (_currentIndex <= 0) return;
    setState(() { _currentIndex--; _face = 0; });
  }

  void _shuffle() {
    setState(() { _items.shuffle(); _currentIndex = 0; _face = 0; });
    HapticFeedback.mediumImpact();
  }

  FlashItem get _current => _items[_currentIndex];

  @override
  Widget build(BuildContext context) {
    final progress = (_currentIndex + 1) / _items.length;
    final tts = context.watch<TtsService>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                          color: AppTheme.card, borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border)),
                      child: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textSecondary, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(widget.title,
                        style: GoogleFonts.spaceGrotesk(
                            color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  // TTS button
                  GestureDetector(
                    onTap: () => tts.speakWord(_current.front, pronunciation: _current.pronunciation),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                          color: tts.isSpeaking ? AppTheme.accent.withOpacity(0.2) : AppTheme.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: tts.isSpeaking ? AppTheme.accent : AppTheme.border)),
                      child: Icon(tts.isSpeaking ? Icons.stop_rounded : Icons.volume_up_outlined,
                          color: tts.isSpeaking ? AppTheme.accent : AppTheme.textSecondary, size: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _shuffle,
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                          color: AppTheme.card, borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border)),
                      child: const Icon(Icons.shuffle_rounded, color: AppTheme.textSecondary, size: 16),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Progress ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_currentIndex + 1} / ${_items.length}',
                          style: GoogleFonts.spaceGrotesk(
                              color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                      // Face indicator pills
                      Row(
                        children: List.generate(_faceCount, (i) => Container(
                          width: i == _face ? 18 : 6, height: 6,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: i == _face
                                ? widget.accentColor
                                : widget.accentColor.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress, minHeight: 5,
                      backgroundColor: AppTheme.card,
                      valueColor: AlwaysStoppedAnimation(widget.accentColor),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Card ──────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: _flip,
                  onHorizontalDragEnd: (d) {
                    if (d.primaryVelocity! < -300) _next();
                    if (d.primaryVelocity! > 300) _prev();
                  },
                  child: SlideTransition(
                    position: _slideAnim,
                    child: AnimatedBuilder(
                      animation: _flipAnim,
                      builder: (context, _) {
                        final angle = _flipAnim.value;
                        final showFront = angle.abs() <= pi / 2;
                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(angle),
                          alignment: Alignment.center,
                          child: showFront
                              ? _CardFace(
                                  item: _current,
                                  faceIndex: _face,
                                  accentColor: widget.accentColor,
                                  onSpeak: (t) => tts.speak(t),
                                )
                              : Transform(
                                  transform: Matrix4.identity()..rotateY(pi),
                                  alignment: Alignment.center,
                                  child: _CardFace(
                                    item: _current,
                                    faceIndex: _face,
                                    accentColor: widget.accentColor,
                                    onSpeak: (t) => tts.speak(t),
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text('← swipe back  •  tap to flip  •  swipe next →',
                style: GoogleFonts.inter(color: AppTheme.textSecondary.withOpacity(0.4), fontSize: 11)),
            const SizedBox(height: 16),

            // ── Nav ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Row(
                children: [
                  _NavBtn(icon: Icons.arrow_back_rounded,
                      onTap: _currentIndex > 0 ? _prev : null,
                      color: AppTheme.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _flip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accentColor, foregroundColor: AppTheme.bg,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: Icon(_faceCount > 2 && _face == 0
                          ? Icons.flip_rounded : Icons.translate_rounded, size: 17),
                      label: Text(_faceLabel, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _NavBtn(icon: Icons.arrow_forward_rounded,
                      onTap: _currentIndex < _items.length - 1 ? _next : null,
                      color: widget.accentColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _faceLabel {
    final nextFace = (_face + 1) % _faceCount;
    switch (_availableFaces[nextFace]) {
      case 0: return 'Show Word';
      case 1: return 'Show Meaning';
      case 2: return 'Show Synonyms';
      case 3: return 'Show Antonyms';
      default: return 'Flip';
    }
  }
}

// ─── Card face renderer ───────────────────────────────────────────────────────

class _CardFace extends StatelessWidget {
  final FlashItem item;
  final int faceIndex; // 0=word, 1=meaning, 2=synonyms, 3=antonyms
  final Color accentColor;
  final ValueChanged<String> onSpeak;

  const _CardFace({
    required this.item, required this.faceIndex,
    required this.accentColor, required this.onSpeak,
  });

  // face 0 = word (front)
  bool get isFront => faceIndex == 0;

  Color get _faceColor {
    switch (faceIndex) {
      case 0: return AppTheme.textPrimary;
      case 1: return accentColor;
      case 2: return const Color(0xFF06D6A0); // synonym green
      case 3: return AppTheme.rose;            // antonym red
      default: return accentColor;
    }
  }

  String get _faceLabel {
    switch (faceIndex) {
      case 0: return item.type == 'word' ? 'WORD' : 'PHRASE';
      case 1: return 'MEANING';
      case 2: return 'SYNONYMS';
      case 3: return 'ANTONYMS';
      default: return '';
    }
  }

  IconData get _faceIcon {
    switch (faceIndex) {
      case 0: return item.type == 'word' ? Icons.abc_rounded : Icons.format_quote_rounded;
      case 1: return Icons.translate_rounded;
      case 2: return Icons.compare_arrows_rounded;
      case 3: return Icons.swap_horiz_rounded;
      default: return Icons.info_outline;
    }
  }

  List<String> get _tags {
    if (faceIndex == 2) return item.synonyms;
    if (faceIndex == 3) return item.antonyms;
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final color = _faceColor;
    final tags = _tags;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isFront ? AppTheme.card : color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isFront ? AppTheme.border : color.withOpacity(0.5),
          width: isFront ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isFront ? Colors.black : color).withOpacity(0.12),
            blurRadius: 24, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Label badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isFront ? AppTheme.surface : color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_faceIcon, size: 14, color: isFront ? AppTheme.textSecondary : color),
                const SizedBox(width: 6),
                Text(_faceLabel,
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: isFront ? AppTheme.textSecondary : color)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Synonyms / Antonyms face ────────────────────────────────────
          if (tags.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Wrap(
                spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
                children: tags.map((t) => GestureDetector(
                  onTap: () => onSpeak(t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: color.withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t,
                            style: GoogleFonts.spaceGrotesk(
                                color: color, fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 6),
                        Icon(Icons.volume_up_outlined, color: color.withOpacity(0.6), size: 14),
                      ],
                    ),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Text('Tap any word to hear it',
                style: GoogleFonts.inter(
                    color: color.withOpacity(0.5), fontSize: 11)),
          ]

          // ── Word face ───────────────────────────────────────────────────
          else if (faceIndex == 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: GestureDetector(
                onTap: () => onSpeak(item.front),
                child: Text(item.front,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.textPrimary, fontSize: 30,
                        fontWeight: FontWeight.w800, height: 1.2)),
              ),
            ),
            if (item.pronunciation != null) ...[
              const SizedBox(height: 8),
              Text('/${item.pronunciation}/',
                  style: GoogleFonts.inter(
                      color: AppTheme.accent.withOpacity(0.7),
                      fontSize: 14, fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_outlined, size: 13, color: AppTheme.textSecondary.withOpacity(0.4)),
                const SizedBox(width: 4),
                Text('tap to flip', style: GoogleFonts.inter(
                    color: AppTheme.textSecondary.withOpacity(0.4), fontSize: 11)),
              ],
            ),
          ]

          // ── Meaning face ────────────────────────────────────────────────
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(item.back,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                      color: color, fontSize: 19,
                      fontWeight: FontWeight.w700, height: 1.3)),
            ),
            if (item.example != null) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: GestureDetector(
                  onTap: () => onSpeak(item.example!),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('"${item.example}"',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                  color: AppTheme.textSecondary, fontSize: 13,
                                  fontStyle: FontStyle.italic, height: 1.5)),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.volume_up_outlined, color: AppTheme.textSecondary.withOpacity(0.5), size: 14),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  const _NavBtn({required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 46, height: 46,
      decoration: BoxDecoration(
        color: onTap != null ? color.withOpacity(0.1) : AppTheme.card.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: onTap != null ? color.withOpacity(0.3) : AppTheme.border),
      ),
      child: Icon(icon,
          color: onTap != null ? color : AppTheme.textSecondary.withOpacity(0.3), size: 20),
    ),
  );
}
