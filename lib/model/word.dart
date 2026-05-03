// lib/models/word.dart

class Word {
  final String id;
  final String word;
  final String meaning;
  final String sentence;
  final bool isBookmarked;
  final DateTime createdAt;
  final List<String> synonyms;
  final List<String> antonyms;
  final String? pronunciation;

  Word({
    required this.id,
    required this.word,
    required this.meaning,
    required this.sentence,
    this.isBookmarked = false,
    DateTime? createdAt,
    this.synonyms = const [],
    this.antonyms = const [],
    this.pronunciation,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get hasSynonyms => synonyms.isNotEmpty;
  bool get hasAntonyms => antonyms.isNotEmpty;
  bool get hasPronunciation =>
      pronunciation != null && pronunciation!.trim().isNotEmpty;

  Map<String, dynamic> toMap() => {
        'word': word,
        'meaning': meaning,
        'sentence': sentence,
        'isBookmarked': isBookmarked,
        'createdAt': createdAt.toIso8601String(),
        'synonyms': synonyms,
        'antonyms': antonyms,
        'pronunciation': pronunciation ?? '',
      };

  factory Word.fromMap(String id, Map<String, dynamic> map) => Word(
        id: id,
        word: map['word'] ?? '',
        meaning: map['meaning'] ?? '',
        sentence: map['sentence'] ?? '',
        isBookmarked: map['isBookmarked'] ?? false,
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
            : DateTime.now(),
        synonyms: _parseList(map['synonyms']),
        antonyms: _parseList(map['antonyms']),
        pronunciation: (map['pronunciation'] as String? ?? '').isEmpty
            ? null
            : map['pronunciation'],
      );

  static List<String> _parseList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  Word copyWith({
    String? id,
    String? word,
    String? meaning,
    String? sentence,
    bool? isBookmarked,
    DateTime? createdAt,
    List<String>? synonyms,
    List<String>? antonyms,
    String? pronunciation,
    bool clearPronunciation = false,
  }) =>
      Word(
        id: id ?? this.id,
        word: word ?? this.word,
        meaning: meaning ?? this.meaning,
        sentence: sentence ?? this.sentence,
        isBookmarked: isBookmarked ?? this.isBookmarked,
        createdAt: createdAt ?? this.createdAt,
        synonyms: synonyms ?? this.synonyms,
        antonyms: antonyms ?? this.antonyms,
        pronunciation:
            clearPronunciation ? null : (pronunciation ?? this.pronunciation),
      );
}
