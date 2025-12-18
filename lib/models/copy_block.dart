import 'dart:convert';

class CopyBlock {
  final String id;
  final String content;
  final String type;
  final bool isExpanded;
  final DateTime createdAt;

  CopyBlock({
    required this.id,
    required this.content,
    this.type = 'text',
    this.isExpanded = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  CopyBlock copyWith({
    String? id,
    String? content,
    String? type,
    bool? isExpanded,
    DateTime? createdAt,
  }) {
    return CopyBlock(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      isExpanded: isExpanded ?? this.isExpanded,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'type': type,
      'isExpanded': isExpanded,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory CopyBlock.fromMap(Map<String, dynamic> map) {
    return CopyBlock(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      type: map['type'] ?? 'text',
      isExpanded: map['isExpanded'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  String toJson() => json.encode(toMap());

  factory CopyBlock.fromJson(String source) => CopyBlock.fromMap(json.decode(source));
}