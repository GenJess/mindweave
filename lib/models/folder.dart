import 'dart:convert';

class Folder {
  final String id;
  final String name;
  final String color;
  final String icon;
  final DateTime createdAt;
  final DateTime modifiedAt;

  Folder({
    required this.id,
    required this.name,
    this.color = '#007AFF',
    this.icon = 'folder',
    DateTime? createdAt,
    DateTime? modifiedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  Folder copyWith({
    String? id,
    String? name,
    String? color,
    String? icon,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'modifiedAt': modifiedAt.millisecondsSinceEpoch,
    };
  }

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      color: map['color'] ?? '#007AFF',
      icon: map['icon'] ?? 'folder',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(map['modifiedAt'] ?? 0),
    );
  }

  String toJson() => json.encode(toMap());

  factory Folder.fromJson(String source) => Folder.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Folder(id: $id, name: $name, color: $color, icon: $icon, createdAt: $createdAt, modifiedAt: $modifiedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Folder &&
        other.id == id &&
        other.name == name &&
        other.color == color &&
        other.icon == icon &&
        other.createdAt == createdAt &&
        other.modifiedAt == modifiedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        color.hashCode ^
        icon.hashCode ^
        createdAt.hashCode ^
        modifiedAt.hashCode;
  }
}

// Default folders
class DefaultFolders {
  static final List<Folder> defaultFolders = [
    Folder(
      id: 'all',
      name: 'All Notes',
      color: '#007AFF',
      icon: 'notes',
    ),
    Folder(
      id: 'personal',
      name: 'Personal',
      color: '#34C759',
      icon: 'person',
    ),
    Folder(
      id: 'work',
      name: 'Work',
      color: '#FF9500',
      icon: 'work',
    ),
    Folder(
      id: 'ideas',
      name: 'Ideas',
      color: '#AF52DE',
      icon: 'lightbulb',
    ),
  ];
}