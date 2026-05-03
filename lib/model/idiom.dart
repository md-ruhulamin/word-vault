// lib/models/idiom.dart

class Idiom {
  final String id;
  final String phrase;
  final String meaning;
  final String example;
  final bool isBookmarked;
  final DateTime createdAt;

  Idiom({
    required this.id,
    required this.phrase,
    required this.meaning,
    required this.example,
    this.isBookmarked = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'phrase': phrase,
      'meaning': meaning,
      'example': example,
      'isBookmarked': isBookmarked,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Idiom.fromMap(String id, Map<String, dynamic> map) {
    return Idiom(
      id: id,
      phrase: map['phrase'] ?? '',
      meaning: map['meaning'] ?? '',
      example: map['example'] ?? '',
      isBookmarked: map['isBookmarked'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Idiom copyWith({
    String? id,
    String? phrase,
    String? meaning,
    String? example,
    bool? isBookmarked,
    DateTime? createdAt,
  }) {
    return Idiom(
      id: id ?? this.id,
      phrase: phrase ?? this.phrase,
      meaning: meaning ?? this.meaning,
      example: example ?? this.example,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
