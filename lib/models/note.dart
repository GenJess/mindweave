import 'dart:convert';
import 'package:mindweave/models/copy_block.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final String folderId;
  final List<CopyBlock> copyBlocks;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final bool isPinned;
  final List<String> tags;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.folderId = 'all',
    List<CopyBlock>? copyBlocks,
    DateTime? createdAt,
    DateTime? modifiedAt,
    this.isPinned = false,
    List<String>? tags,
  })  : copyBlocks = copyBlocks ?? [],
        createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now(),
        tags = tags ?? [];

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? folderId,
    List<CopyBlock>? copyBlocks,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isPinned,
    List<String>? tags,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      folderId: folderId ?? this.folderId,
      copyBlocks: copyBlocks ?? this.copyBlocks,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? this.tags,
    );
  }

  String get previewText {
    if (content.isEmpty) return 'No additional text';
    final cleanContent = content.replaceAll(RegExp(r'\[BLOCK:.*?\[/BLOCK\]', dotAll: true), '').trim();
    if (cleanContent.isEmpty) return 'Copy blocks only';
    return cleanContent.length > 100 
        ? '${cleanContent.substring(0, 100)}...' 
        : cleanContent;
  }

  int get wordCount {
    return content.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'folderId': folderId,
      'copyBlocks': copyBlocks.map((block) => block.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'modifiedAt': modifiedAt.millisecondsSinceEpoch,
      'isPinned': isPinned,
      'tags': tags,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      folderId: map['folderId'] ?? 'all',
      copyBlocks: List<CopyBlock>.from(
        (map['copyBlocks'] ?? []).map((x) => CopyBlock.fromMap(x)),
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(map['modifiedAt'] ?? 0),
      isPinned: map['isPinned'] ?? false,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  String toJson() => json.encode(toMap());

  factory Note.fromJson(String source) => Note.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Note(id: $id, title: $title, content: $content, folderId: $folderId, copyBlocks: $copyBlocks, createdAt: $createdAt, modifiedAt: $modifiedAt, isPinned: $isPinned, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Note &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.folderId == folderId &&
        _listEquals(other.copyBlocks, copyBlocks) &&
        other.createdAt == createdAt &&
        other.modifiedAt == modifiedAt &&
        other.isPinned == isPinned &&
        _listEquals(other.tags, tags);
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        content.hashCode ^
        folderId.hashCode ^
        copyBlocks.hashCode ^
        createdAt.hashCode ^
        modifiedAt.hashCode ^
        isPinned.hashCode ^
        tags.hashCode;
  }
}

// Sample notes for demo
class SampleNotes {
  static final List<Note> sampleNotes = [
    Note(
      id: '1',
      title: 'Welcome to QuickNote',
      content: '''Welcome to QuickNote! This is your first note.

QuickNote makes it easy to capture ideas and organize them with copy blocks.

[BLOCK: API Key Example]
sk-1234567890abcdef1234567890abcdef
[/BLOCK]

Copy blocks are perfect for storing code snippets, API keys, passwords, or any text you need to copy quickly.

Try creating your own notes and copy blocks!''',
      folderId: 'personal',
      copyBlocks: [
        CopyBlock(
          id: 'cb1',
          content: 'sk-1234567890abcdef1234567890abcdef',
        ),
      ],
      isPinned: true,
      tags: ['welcome', 'tutorial'],
    ),
    Note(
      id: '2',
      title: 'Shopping List',
      content: '''Things to buy this week:

• Milk
• Bread
• Eggs
• Coffee
• Apples

[BLOCK: Grocery Store Info]
Store: Fresh Market
Address: 123 Main St
Phone: (555) 123-4567
Hours: 8am - 10pm
[/BLOCK]''',
      folderId: 'personal',
      copyBlocks: [
        CopyBlock(
          id: 'cb2',
          content: '''Store: Fresh Market
Address: 123 Main St
Phone: (555) 123-4567
Hours: 8am - 10pm''',
        ),
      ],
      tags: ['shopping', 'groceries'],
    ),
    Note(
      id: '3',
      title: 'Meeting Notes - Project Alpha',
      content: '''Meeting with development team about Project Alpha.

Key points discussed:
- Timeline extended by 2 weeks
- Need additional resources for backend
- UI mockups approved

[BLOCK: Action Items]
1. Update project timeline in Jira
2. Request 2 additional backend developers
3. Schedule follow-up meeting for next Friday
4. Send updated requirements to stakeholders
[/BLOCK]

[BLOCK: Next Meeting]
Date: Friday, Next Week
Time: 2:00 PM
Location: Conference Room B
Attendees: Dev team + Product Manager
[/BLOCK]''',
      folderId: 'work',
      copyBlocks: [
        CopyBlock(
          id: 'cb3',
          content: '''1. Update project timeline in Jira
2. Request 2 additional backend developers
3. Schedule follow-up meeting for next Friday
4. Send updated requirements to stakeholders''',
        ),
        CopyBlock(
          id: 'cb4',
          content: '''Date: Friday, Next Week
Time: 2:00 PM
Location: Conference Room B
Attendees: Dev team + Product Manager''',
        ),
      ],
      tags: ['meeting', 'project-alpha', 'work'],
    ),
  ];
}