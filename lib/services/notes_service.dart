import 'package:flutter/foundation.dart';
import 'package:mindweave/models/note.dart';
import 'package:mindweave/models/copy_block.dart';
import 'package:mindweave/services/storage_service.dart';

class NotesService extends ChangeNotifier {
  static final NotesService _instance = NotesService._internal();
  factory NotesService() => _instance;
  NotesService._internal();

  List<Note> _notes = [];
  bool _isLoaded = false;

  List<Note> get notes {
    // Sort notes by modification date (most recent first), then by creation date
    final sortedNotes = List<Note>.from(_notes);
    sortedNotes.sort((a, b) {
      final aTime = a.modifiedAt.isAfter(a.createdAt) ? a.modifiedAt : a.createdAt;
      final bTime = b.modifiedAt.isAfter(b.createdAt) ? b.modifiedAt : b.createdAt;
      return bTime.compareTo(aTime);
    });
    return List.unmodifiable(sortedNotes);
  }
  bool get isLoaded => _isLoaded;

  Future<void> loadNotes() async {
    if (_isLoaded) return;

    try {
      final notesMaps = StorageService.getJsonList('notes');
      if (notesMaps == null || notesMaps.isEmpty) {
        // Load sample notes on first run
        _notes = List.from(SampleNotes.sampleNotes);
        await _saveNotes();
      } else {
        _notes = notesMaps.map((map) => Note.fromMap(map)).toList();
      }
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notes: $e');
      _notes = List.from(SampleNotes.sampleNotes);
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<bool> _saveNotes() async {
    try {
      final notesMaps = _notes.map((note) => note.toMap()).toList();
      return await StorageService.setJsonList('notes', notesMaps);
    } catch (e) {
      debugPrint('Error saving notes: $e');
      return false;
    }
  }

  Future<Note> createNote({
    String? title,
    String? content,
    String? folderId,
    List<String>? tags,
  }) async {
    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title ?? 'Untitled',
      content: content ?? '',
      folderId: folderId ?? 'all',
      tags: tags ?? [],
    );

    _notes.insert(0, note);
    await _saveNotes();
    notifyListeners();
    return note;
  }

  Future<bool> updateNote(Note updatedNote) async {
    final index = _notes.indexWhere((note) => note.id == updatedNote.id);
    if (index == -1) return false;

    final updated = updatedNote.copyWith(modifiedAt: DateTime.now());
    _notes[index] = updated;
    
    // Move updated note to front for quick access
    _notes.removeAt(index);
    _notes.insert(0, updated);
    
    await _saveNotes();
    notifyListeners();
    return true;
  }

  Future<bool> deleteNote(String noteId) async {
    final initialLength = _notes.length;
    _notes.removeWhere((note) => note.id == noteId);
    
    if (_notes.length < initialLength) {
      await _saveNotes();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> pinNote(String noteId, bool isPinned) async {
    final index = _notes.indexWhere((note) => note.id == noteId);
    if (index == -1) return false;

    _notes[index] = _notes[index].copyWith(isPinned: isPinned);
    
    // Sort to put pinned notes at the top
    _notes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.modifiedAt.compareTo(a.modifiedAt);
    });

    await _saveNotes();
    notifyListeners();
    return true;
  }

  Note? getNoteById(String noteId) {
    try {
      return _notes.firstWhere((note) => note.id == noteId);
    } catch (e) {
      return null;
    }
  }

  List<Note> getNotesByFolder(String folderId) {
    if (folderId == 'all') return _notes;
    return _notes.where((note) => note.folderId == folderId).toList();
  }

  List<Note> searchNotes(String query) {
    if (query.isEmpty) return _notes;
    
    final lowerQuery = query.toLowerCase();
    return _notes.where((note) {
      return note.title.toLowerCase().contains(lowerQuery) ||
             note.content.toLowerCase().contains(lowerQuery) ||
             note.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
             note.copyBlocks.any((block) =>
               block.content.toLowerCase().contains(lowerQuery)
             );
    }).toList();
  }

  Future<bool> addCopyBlockToNote(String noteId, CopyBlock copyBlock) async {
    final note = getNoteById(noteId);
    if (note == null) return false;

    final updatedBlocks = List<CopyBlock>.from(note.copyBlocks)..add(copyBlock);
    return await updateNote(note.copyWith(copyBlocks: updatedBlocks));
  }

  Future<bool> removeCopyBlockFromNote(String noteId, String blockId) async {
    final note = getNoteById(noteId);
    if (note == null) return false;

    final updatedBlocks = note.copyBlocks.where((block) => block.id != blockId).toList();
    return await updateNote(note.copyWith(copyBlocks: updatedBlocks));
  }

  Future<bool> updateCopyBlockInNote(String noteId, CopyBlock updatedBlock) async {
    final note = getNoteById(noteId);
    if (note == null) return false;

    final updatedBlocks = note.copyBlocks.map((block) {
      return block.id == updatedBlock.id ? updatedBlock : block;
    }).toList();

    return await updateNote(note.copyWith(copyBlocks: updatedBlocks));
  }

  // Parse copy blocks from note content using markdown-like syntax
  List<CopyBlock> parseCopyBlocksFromContent(String content) {
    final blocks = <CopyBlock>[];
    final blockPattern = RegExp(r'\[BLOCK:\s*([^\]]+)\](.*?)\[/BLOCK\]', dotAll: true);
    final matches = blockPattern.allMatches(content);

    for (final match in matches) {
      final title = match.group(1)?.trim() ?? '';
      final blockContent = match.group(2)?.trim() ?? '';
      
      if (title.isNotEmpty || blockContent.isNotEmpty) {
        blocks.add(CopyBlock(
          id: DateTime.now().millisecondsSinceEpoch.toString() + blocks.length.toString(),
          content: blockContent.isNotEmpty ? blockContent : title,
        ));
      }
    }

    return blocks;
  }

  // Convert copy blocks back to markdown-like syntax
  String generateContentWithBlocks(String content, List<CopyBlock> blocks) {
    var updatedContent = content;
    
    for (final block in blocks) {
      final blockString = '[BLOCK]\n${block.content}\n[/BLOCK]';
      if (!updatedContent.contains(blockString)) {
        updatedContent += '\n\n$blockString';
      }
    }
    
    return updatedContent;
  }

  int getTotalNotesCount() => _notes.length;
  
  int getNotesCountByFolder(String folderId) => getNotesByFolder(folderId).length;

  DateTime? getLastModifiedDate() {
    if (_notes.isEmpty) return null;
    return _notes.map((note) => note.modifiedAt).reduce((a, b) => a.isAfter(b) ? a : b);
  }
}