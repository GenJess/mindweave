import 'package:flutter/foundation.dart';
import 'package:mindweave/models/folder.dart';
import 'package:mindweave/services/storage_service.dart';

class FolderService extends ChangeNotifier {
  static final FolderService _instance = FolderService._internal();
  factory FolderService() => _instance;
  FolderService._internal();

  List<Folder> _folders = [];
  bool _isLoaded = false;

  List<Folder> get folders => List.unmodifiable(_folders);
  bool get isLoaded => _isLoaded;

  Future<void> loadFolders() async {
    if (_isLoaded) return;

    try {
      final folderMaps = StorageService.getJsonList('folders');
      if (folderMaps == null || folderMaps.isEmpty) {
        // Load default folders on first run
        _folders = List.from(DefaultFolders.defaultFolders);
        await _saveFolders();
      } else {
        _folders = folderMaps.map((map) => Folder.fromMap(map)).toList();
      }
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading folders: $e');
      _folders = List.from(DefaultFolders.defaultFolders);
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<bool> _saveFolders() async {
    try {
      final folderMaps = _folders.map((folder) => folder.toMap()).toList();
      return await StorageService.setJsonList('folders', folderMaps);
    } catch (e) {
      debugPrint('Error saving folders: $e');
      return false;
    }
  }

  Future<Folder> createFolder({
    required String name,
    String? color,
    String? icon,
  }) async {
    final folder = Folder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      color: color ?? '#007AFF',
      icon: icon ?? 'folder',
    );

    _folders.add(folder);
    await _saveFolders();
    notifyListeners();
    return folder;
  }

  Future<bool> updateFolder(Folder updatedFolder) async {
    final index = _folders.indexWhere((folder) => folder.id == updatedFolder.id);
    if (index == -1) return false;

    _folders[index] = updatedFolder.copyWith(modifiedAt: DateTime.now());
    await _saveFolders();
    notifyListeners();
    return true;
  }

  Future<bool> deleteFolder(String folderId) async {
    // Don't allow deletion of default folders
    if (['all', 'personal', 'work', 'ideas'].contains(folderId)) {
      return false;
    }

    final initialLength = _folders.length;
    _folders.removeWhere((folder) => folder.id == folderId);
    
    if (_folders.length < initialLength) {
      await _saveFolders();
      notifyListeners();
      return true;
    }
    return false;
  }

  Folder? getFolderById(String folderId) {
    try {
      return _folders.firstWhere((folder) => folder.id == folderId);
    } catch (e) {
      return null;
    }
  }

  String getFolderName(String folderId) {
    final folder = getFolderById(folderId);
    return folder?.name ?? 'Unknown Folder';
  }

  String getFolderColor(String folderId) {
    final folder = getFolderById(folderId);
    return folder?.color ?? '#007AFF';
  }

  String getFolderIcon(String folderId) {
    final folder = getFolderById(folderId);
    return folder?.icon ?? 'folder';
  }

  List<Folder> getCustomFolders() {
    return _folders.where((folder) => !['all', 'personal', 'work', 'ideas'].contains(folder.id)).toList();
  }

  List<Folder> getDefaultFolders() {
    return _folders.where((folder) => ['all', 'personal', 'work', 'ideas'].contains(folder.id)).toList();
  }

  bool isFolderNameAvailable(String name, {String? excludeId}) {
    return !_folders.any((folder) => 
      folder.name.toLowerCase() == name.toLowerCase() && folder.id != excludeId);
  }

  Future<bool> reorderFolders(List<Folder> newOrder) async {
    _folders = newOrder;
    await _saveFolders();
    notifyListeners();
    return true;
  }

  int getTotalFoldersCount() => _folders.length;

  // Color options for folders
  static const List<String> folderColors = [
    '#007AFF', // Blue
    '#34C759', // Green
    '#FF9500', // Orange
    '#AF52DE', // Purple
    '#FF3B30', // Red
    '#5AC8FA', // Light Blue
    '#FFCC00', // Yellow
    '#FF2D92', // Pink
    '#64D2FF', // Cyan
    '#30D158', // Mint
  ];

  // Icon options for folders
  static const List<String> folderIcons = [
    'folder',
    'work',
    'person',
    'lightbulb',
    'school',
    'home',
    'favorite',
    'shopping_cart',
    'travel_explore',
    'fitness_center',
    'restaurant',
    'music_note',
    'camera_alt',
    'book',
    'code',
  ];
}