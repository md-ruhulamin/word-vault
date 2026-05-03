

import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocab_store/app_provider.dart';
import 'package:vocab_store/app_theme.dart';
import 'package:vocab_store/model/word.dart';
       // adjust path if needed

// ─── Entry point ────────────────────────────────────────────────────────────

class WordScrambleScreen extends StatefulWidget {
  /// Pass a pre-filtered list or leave null to use ALL words from AppProvider.
  final List<Word>? wordList;

  const WordScrambleScreen({super.key, this.wordList});

  @override
  State<WordScrambleScreen> createState() => _WordScrambleScreenState();
}

// ─── State ───────────────────────────────────────────────────────────────────

class _WordScrambleScreenState extends State<WordScrambleScreen>
    with TickerProviderStateMixin {

  // ── word session data ──
  late List<Word> _sessionWords;
  int _currentIndex = 0;
  int _correctCount = 0;

  // ── letter tile data ──
  // Each element: {'letter': 'A', 'id': unique int, 'placed': false}
  List<Map<String, dynamic>> _pool = [];   // shuffled letters still available
  List<Map<String, dynamic>?> _slots = []; // answer slots (null = empty)

  // ── game state ──
  bool _submitted = false;
  bool _isCorrect = false;
  bool _showResult = false;
  bool _sessionComplete = false;

  // ── animations ──
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _successCtrl;
  late Animation<double> _successAnim;
  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  // ── confetti (optional – un-comment if you add the package) ──
  late ConfettiController _confettiCtrl;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildSession();
  }

  void _buildSession() {
    final provider = context.read<AppProvider>();
    final source = widget.wordList ?? provider.words;

    // Filter: only single words (scramble makes sense for single words)
    final eligible = source.where((w) => w.word.trim().contains(RegExp(r'^[a-zA-Z]+$'))).toList();
    eligible.shuffle();

    _sessionWords = eligible.take(15).toList(); // up to 15 per session
    if (_sessionWords.isEmpty) return;

    _progressCtrl.forward(from: 0);
    _loadWord(_currentIndex);
  }

  void _initAnimations() {
    // Shake on wrong answer
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );

    // Pulse on correct answer
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successAnim = Tween<double>(begin: 1, end: 1.08).animate(
      CurvedAnimation(parent: _successCtrl, curve: Curves.easeOut),
    );

    // Progress bar
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _progressAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _successCtrl.dispose();
    _progressCtrl.dispose();
    // _confettiCtrl.dispose();
    super.dispose();
  }

  // ─── game logic ──────────────────────────────────────────────────────────

  void _loadWord(int index) {
    final word = _sessionWords[index].word.toUpperCase();
    final letters = word.split('');

    // Assign a unique ID to each letter (handles duplicate letters)
    int idCounter = 0;
    final pool = letters.map((l) => {
      'letter': l,
      'id': idCounter++,
      'placed': false,
    }).toList();

    // Shuffle until the order is different from the original
    pool.shuffle();
    while (pool.map((e) => e['letter']).join() == word) {
      pool.shuffle();
    }

    setState(() {
      _pool = pool;
      _slots = List<Map<String, dynamic>?>.filled(word.length, null);
      _submitted = false;
      _isCorrect = false;
      _showResult = false;
    });

    // Animate progress bar
    final targetProgress = (_currentIndex) / _sessionWords.length;
    _progressCtrl.animateTo(targetProgress,
        duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
  }

  void _tapPoolLetter(int poolIndex) {
    if (_submitted) return;
    final tile = _pool[poolIndex];
    if (tile['placed'] as bool) return;

    // Find first empty slot
    final emptySlot = _slots.indexWhere((s) => s == null);
    if (emptySlot == -1) return;

    setState(() {
      _pool[poolIndex]['placed'] = true;
      _slots[emptySlot] = tile;
    });
  }

  void _tapSlotLetter(int slotIndex) {
    if (_submitted) return;
    final tile = _slots[slotIndex];
    if (tile == null) return;

    // Find the matching pool entry and un-place it
    final poolIdx = _pool.indexWhere((p) => p['id'] == tile['id']);
    setState(() {
      if (poolIdx != -1) _pool[poolIdx]['placed'] = false;
      _slots[slotIndex] = null;
    });
  }

  void _submit() {
    if (_submitted) return;
    final answer = _slots.map((s) => s?['letter'] ?? '').join();
    final correct = _sessionWords[_currentIndex].word.toUpperCase();
    final isCorrect = answer == correct;

    setState(() {
      _submitted = true;
      _isCorrect = isCorrect;
      _showResult = true;
    });

    if (isCorrect) {
      _correctCount++;
      _successCtrl.forward(from: 0).then((_) => _successCtrl.reverse());
      // _confettiCtrl.play();
      Future.delayed(const Duration(milliseconds: 1600), _next);
    } else {
      _shakeCtrl.forward(from: 0);
    }
  }

  void _next() {
    if (_currentIndex + 1 >= _sessionWords.length) {
      _progressCtrl.animateTo(1.0,
          duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
      Future.delayed(const Duration(milliseconds: 450), () {
        setState(() => _sessionComplete = true);
      });
      return;
    }
    setState(() => _currentIndex++);
    _loadWord(_currentIndex);
  }

  void _restartSession() {
    setState(() {
      _currentIndex = 0;
      _correctCount = 0;
      _sessionComplete = false;
    });
    _sessionWords.shuffle();
    _loadWord(0);
  }

  // ─── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_sessionWords.isEmpty) return _emptyState();
    if (_sessionComplete) return _completionScreen();

    final word = _sessionWords[_currentIndex];

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    _buildWordInfo(word),
                    const SizedBox(height: 32),
                    _buildAnswerSlots(),
                    const SizedBox(height: 24),
                    if (_showResult) _buildResultBanner(),
                    const SizedBox(height: 24),
                    _buildLetterPool(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textSecondary, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Word Scramble',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                '${_currentIndex + 1} / ${_sessionWords.length}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return AnimatedBuilder(
      animation: _progressCtrl,
      builder: (_, __) {
        final progress = (_currentIndex + (_submitted && _isCorrect ? 1 : 0)) /
            _sessionWords.length;
        return LinearProgressIndicator(
          value: progress,
          backgroundColor: AppTheme.border,
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
          minHeight: 3,
        );
      },
    );
  }

  Widget _buildWordInfo(Word word) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _pill('📖 Spell this word', AppTheme.accent.withOpacity(0.15), AppTheme.accent),
              _pill('✅ $_correctCount correct', AppTheme.gold.withOpacity(0.12), AppTheme.gold),
            ],
          ),
          const SizedBox(height: 16),
          // Meaning
          const Text(
            'Meaning:',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            word.meaning,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          // if (word.sentence.isNotEmpty) ...[
          //   const SizedBox(height: 12),
          //   Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          //     decoration: BoxDecoration(
          //       color: AppTheme.bg,
          //       borderRadius: BorderRadius.circular(8),
          //       border: Border.all(color: AppTheme.border),
          //     ),
          //     child: Text(
          //       '"${word.sentence}"',
          //       style: const TextStyle(
          //         color: AppTheme.textSecondary,
          //         fontSize: 13,
          //         fontStyle: FontStyle.italic,
          //         height: 1.4,
          //       ),
          //     ),
          //   ),
          //],
        ],
      ),
    );
  }

  Widget _pill(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildAnswerSlots() {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) {
        final offset = _submitted && !_isCorrect
            ? sin(_shakeAnim.value * pi * 6) * 8.0
            : 0.0;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: ScaleTransition(
        scale: _isCorrect ? _successAnim : const AlwaysStoppedAnimation(1.0),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(_slots.length, (i) => _buildSlot(i)),
        ),
      ),
    );
  }

  Widget _buildSlot(int i) {
    final tile = _slots[i];
    final filled = tile != null;
    final Color borderColor;
    final Color bgColor;

    if (_submitted) {
      borderColor = _isCorrect ? AppTheme.accent : AppTheme.rose;
      bgColor = _isCorrect
          ? AppTheme.accent.withOpacity(0.15)
          : AppTheme.rose.withOpacity(0.12);
    } else {
      borderColor = filled ? AppTheme.accent : AppTheme.border;
      bgColor = filled ? AppTheme.accent.withOpacity(0.1) : AppTheme.card;
    }

    return GestureDetector(
      onTap: filled && !_submitted ? () => _tapSlotLetter(i) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 50,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: filled ? 1.5 : 1),
        ),
        alignment: Alignment.center,
        child: filled
            ? Text(
                tile!['letter'] as String,
                style: TextStyle(
                  color: _submitted
                      ? (_isCorrect ? AppTheme.accent : AppTheme.rose)
                      : AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              )
            : const Text(
                '_',
                style: TextStyle(
                  color: AppTheme.border,
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                ),
              ),
      ),
    );
  }

  Widget _buildResultBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _isCorrect
            ? AppTheme.accent.withOpacity(0.12)
            : AppTheme.rose.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isCorrect ? AppTheme.accent : AppTheme.rose,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Text(
            _isCorrect ? '🎉' : '❌',
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isCorrect ? 'Perfect spelling!' : 'Not quite right',
                  style: TextStyle(
                    color: _isCorrect ? AppTheme.accent : AppTheme.rose,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!_isCorrect) ...[
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      text: 'Correct spelling: ',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      children: [
                        TextSpan(
                          text: _sessionWords[_currentIndex].word,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterPool() {
    return Column(
      children: [
        const Text(
          'TAP LETTERS TO SPELL',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: List.generate(
            _pool.length,
            (i) => _buildPoolTile(i),
          ),
        ),
      ],
    );
  }

  Widget _buildPoolTile(int i) {
    final tile = _pool[i];
    final placed = tile['placed'] as bool;

    return GestureDetector(
      onTap: !placed && !_submitted ? () => _tapPoolLetter(i) : null,
      child: AnimatedOpacity(
        opacity: placed ? 0.2 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 52,
          height: 58,
          decoration: BoxDecoration(
            color: placed ? AppTheme.card : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: placed ? AppTheme.border : AppTheme.accent.withOpacity(0.5),
              width: placed ? 1 : 1.5,
            ),
            boxShadow: placed
                ? []
                : [
                    BoxShadow(
                      color: AppTheme.accent.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: Text(
            tile['letter'] as String,
            style: TextStyle(
              color: placed ? AppTheme.border : AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final allFilled = _slots.every((s) => s != null);

    return Column(
      children: [
        if (!_submitted) ...[
          // Clear button
          if (_slots.any((s) => s != null))
            TextButton.icon(
              onPressed: _clearAll,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Clear all'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
            ),
          const SizedBox(height: 12),
          // Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: allFilled ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: allFilled ? AppTheme.accent : AppTheme.border,
                foregroundColor: AppTheme.bg,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                disabledBackgroundColor: AppTheme.border,
                disabledForegroundColor: AppTheme.textSecondary,
              ),
              child: const Text(
                'CHECK ANSWER',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1.5),
              ),
            ),
          ),
        ] else if (!_isCorrect) ...[
          // Wrong – let user go next manually
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _next,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                _currentIndex + 1 >= _sessionWords.length ? 'FINISH' : 'NEXT WORD',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1.2),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentSoft,
                foregroundColor: AppTheme.bg,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ] else ...[
          // Correct – auto advancing, show indicator
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Next word…',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _clearAll() {
    setState(() {
      for (var tile in _pool) {
        tile['placed'] = false;
      }
      _slots = List<Map<String, dynamic>?>.filled(_slots.length, null);
    });
  }

  // ─── Completion screen ────────────────────────────────────────────────────

  Widget _completionScreen() {
    final total = _sessionWords.length;
    final pct = ((_correctCount / total) * 100).round();
    final String emoji;
    final String message;

    if (pct == 100) {
      emoji = '🏆';
      message = 'Perfect Score! You\'re a spelling champion!';
    } else if (pct >= 70) {
      emoji = '🎉';
      message = 'Great job! Keep practising to reach 100%!';
    } else {
      emoji = '💪';
      message = 'Good effort! A little more practice and you\'ll nail it!';
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 24),
              const Text(
                'Session Complete!',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 40),
              // Score card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _scoreStat('$_correctCount / $total', 'Words correct', AppTheme.accent),
                    _scoreDivider(),
                    _scoreStat('$pct%', 'Accuracy', AppTheme.gold),
                    _scoreDivider(),
                    _scoreStat('${total - _correctCount}', 'Missed', AppTheme.rose),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _restartSession,
                  icon: const Icon(Icons.replay_rounded, size: 20),
                  label: const Text(
                    'PLAY AGAIN',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 1.2),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: const BorderSide(color: AppTheme.border),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'BACK TO DICTIONARY',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 1.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _scoreDivider() {
    return Container(width: 1, height: 40, color: AppTheme.border);
  }

  // ─── Empty state ──────────────────────────────────────────────────────────

  Widget _emptyState() {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Word Scramble', style: TextStyle(color: AppTheme.textPrimary)),
        leading: const BackButton(color: AppTheme.textSecondary),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📭', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 20),
              const Text(
                'No words yet!',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                'Add some single-word entries to your dictionary first, then come back to play.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('GO TO DICTIONARY'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}