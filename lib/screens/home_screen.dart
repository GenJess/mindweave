import 'package:flutter/material.dart';
import 'package:mindweave/models/note.dart';
import 'package:mindweave/models/folder.dart';
import 'package:mindweave/services/notes_service.dart';
import 'package:mindweave/services/folder_service.dart';
import 'package:mindweave/screens/note_editor_screen.dart';
import 'package:mindweave/screens/search_screen.dart';
import 'package:mindweave/screens/folders_screen.dart';
import 'package:mindweave/widgets/quick_add_bottom_sheet.dart';
import 'package:mindweave/widgets/note_card.dart';
import 'package:mindweave/widgets/custom_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotesService _notesService = NotesService();
  final FolderService _folderService = FolderService();
  int _selectedIndex = 0;
  String _selectedFolderId = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _notesService.loadNotes(),
        _folderService.loadFolders(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onBottomNavTap(int index) {
    if (index == 4) {
      // Handle the expandable FAB action
      _showQuickAddOptions();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _showQuickAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickAddBottomSheet(
        onCreateNote: _createNewNote,
      ),
    );
  }

  void _createNewNote() async {
    print('Creating new note from home screen');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NoteEditorScreen(),
      ),
    ).then((_) {
      print('Returned from note editor, reloading data');
      _loadData();
    });
  }

  List<Note> get _filteredNotes {
    List<Note> filtered;
    if (_selectedFolderId == 'all') {
      filtered = List.from(_notesService.notes);
    } else {
      filtered = _notesService.notes
          .where((note) => note.folderId == _selectedFolderId)
          .toList();
    }
    
    // Sort by chronological order (newest first), with pinned notes at top
    filtered.sort((a, b) {
      // Pinned notes first
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      
      // Then by most recent
      return b.modifiedAt.compareTo(a.modifiedAt);
    });
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Widget> pages = [
      _buildNotesPage(),
      const SearchScreen(),
      const FoldersScreen(),
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedIndex,
              children: pages,
            ),
      floatingActionButton: null, // Removed duplicate FAB
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildNotesPage() {
    final theme = Theme.of(context);
    final folders = _folderService.folders;
    final notes = _filteredNotes;

    return SafeArea(
      child: Column(
        children: [
          // App Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'MindWeave',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                // Instructions/Tips
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tap to share & delete',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Folder Filter Chips (only show when there are folders to filter by)
          if (folders.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: folders.length,
                itemBuilder: (context, index) {
                  final folder = folders[index];
                  final noteCount = _notesService.notes
                      .where((note) => note.folderId == folder.id)
                      .length;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: _selectedFolderId == folder.id,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.folder,
                            size: 16,
                            color: _selectedFolderId == folder.id
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${folder.name} ($noteCount)',
                            style: TextStyle(
                              color: _selectedFolderId == folder.id
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFolderId = folder.id;
                          });
                        } else {
                          setState(() {
                            _selectedFolderId = 'all';
                          });
                        }
                      },
                      backgroundColor: theme.colorScheme.surface,
                      selectedColor: theme.colorScheme.primary,
                      side: BorderSide(
                        color: _selectedFolderId == folder.id
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 16),

          // Notes List
          Expanded(
            child: notes.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: NoteCard(
                            note: note,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NoteEditorScreen(note: note),
                                ),
                              ).then((_) => _loadData());
                            },
                            onDelete: () => _deleteNote(note),
                            onPin: () => _togglePin(note),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFolderId == 'all' 
                ? 'No notes yet' 
                : 'No notes in this folder',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first note',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewNote,
            icon: const Icon(Icons.add),
            label: const Text('Create Note'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNote(Note note) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _notesService.deleteNote(note.id);
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note "${note.title}" deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _togglePin(Note note) async {
    final updatedNote = note.copyWith(isPinned: !note.isPinned);
    await _notesService.updateNote(updatedNote);
    setState(() {});
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            note.isPinned 
                ? 'Note unpinned' 
                : 'Note pinned',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}