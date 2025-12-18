import 'package:flutter/material.dart';
import 'package:mindweave/models/folder.dart';
import 'package:mindweave/services/folder_service.dart';
import 'package:mindweave/services/notes_service.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final FolderService _folderService = FolderService();
  final NotesService _notesService = NotesService();

  void _showCreateFolderDialog() {
    showDialog(
      context: context,
      builder: (context) => _FolderDialog(
        title: 'Create Folder',
        onSave: (name, color, icon) async {
          await _folderService.createFolder(
            name: name,
            color: color,
            icon: icon,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Folder "$name" created'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditFolderDialog(Folder folder) {
    showDialog(
      context: context,
      builder: (context) => _FolderDialog(
        title: 'Edit Folder',
        initialName: folder.name,
        initialColor: folder.color,
        initialIcon: folder.icon,
        onSave: (name, color, icon) async {
          final updatedFolder = folder.copyWith(
            name: name,
            color: color,
            icon: icon,
          );
          await _folderService.updateFolder(updatedFolder);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Folder "$name" updated'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _deleteFolder(Folder folder) {
    // Check if folder has notes
    final notesCount = _notesService.getNotesCountByFolder(folder.id);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${folder.name}"?'),
            if (notesCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'This folder contains $notesCount note${notesCount == 1 ? '' : 's'}. Notes will be moved to "Personal" folder.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Move notes to personal folder
              if (notesCount > 0) {
                final notes = _notesService.getNotesByFolder(folder.id);
                for (final note in notes) {
                  await _notesService.updateNote(note.copyWith(folderId: 'personal'));
                }
              }
              
              // Delete folder
              await _folderService.deleteFolder(folder.id);
              
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Folder "${folder.name}" deleted'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: theme.colorScheme.surface,
            title: const Text('Folders'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_outlined),
                onPressed: _showCreateFolderDialog,
                tooltip: 'Create folder',
              ),
            ],
          ),
          
          // Folders list
          ListenableBuilder(
            listenable: Listenable.merge([_folderService, _notesService]),
            builder: (context, child) {
              final folders = _folderService.folders;
              
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final folder = folders[index];
                    final notesCount = _notesService.getNotesCountByFolder(folder.id);
                    final isDefault = ['all', 'personal', 'work', 'ideas'].contains(folder.id);
                    
                    return _FolderTile(
                      folder: folder,
                      notesCount: notesCount,
                      isDefault: isDefault,
                      onEdit: isDefault ? null : () => _showEditFolderDialog(folder),
                      onDelete: isDefault ? null : () => _deleteFolder(folder),
                    );
                  },
                  childCount: folders.length,
                ),
              );
            },
          ),
          
          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}

class _FolderTile extends StatelessWidget {
  final Folder folder;
  final int notesCount;
  final bool isDefault;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _FolderTile({
    required this.folder,
    required this.notesCount,
    required this.isDefault,
    this.onEdit,
    this.onDelete,
  });

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work_outline;
      case 'person':
        return Icons.person_outline;
      case 'lightbulb':
        return Icons.lightbulb_outline;
      case 'school':
        return Icons.school_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'favorite':
        return Icons.favorite_outline;
      case 'shopping_cart':
        return Icons.shopping_cart_outlined;
      case 'travel_explore':
        return Icons.travel_explore_outlined;
      case 'fitness_center':
        return Icons.fitness_center_outlined;
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'music_note':
        return Icons.music_note_outlined;
      case 'camera_alt':
        return Icons.camera_alt_outlined;
      case 'book':
        return Icons.book_outlined;
      case 'code':
        return Icons.code_outlined;
      case 'notes':
        return Icons.notes_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final folderColor = Color(int.parse(folder.color.substring(1), radix: 16) + 0xFF000000);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () {
          // Navigate back to home with this folder selected
          Navigator.pop(context, folder.id);
        },
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: folderColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: folderColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            _getIconData(folder.icon),
            color: folderColor,
            size: 24,
          ),
        ),
        title: Text(
          folder.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '$notesCount note${notesCount == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            if (isDefault) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Default',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: !isDefault
          ? PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit?.call();
                    break;
                  case 'delete':
                    onDelete?.call();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 12),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Delete',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
              child: Icon(
                Icons.more_vert,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            )
          : null,
      ),
    );
  }
}

class _FolderDialog extends StatefulWidget {
  final String title;
  final String? initialName;
  final String? initialColor;
  final String? initialIcon;
  final Function(String name, String color, String icon) onSave;

  const _FolderDialog({
    required this.title,
    required this.onSave,
    this.initialName,
    this.initialColor,
    this.initialIcon,
  });

  @override
  State<_FolderDialog> createState() => _FolderDialogState();
}

class _FolderDialogState extends State<_FolderDialog> {
  late TextEditingController _nameController;
  late String _selectedColor;
  late String _selectedIcon;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedColor = widget.initialColor ?? '#007AFF';
    _selectedIcon = widget.initialIcon ?? 'folder';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Folder name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            
            const SizedBox(height: 20),
            
            // Color selector
            Text(
              'Color',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FolderService.folderColors.map((color) {
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(int.parse(color.substring(1), radix: 16) + 0xFF000000),
                      shape: BoxShape.circle,
                      border: isSelected
                        ? Border.all(color: theme.colorScheme.primary, width: 3)
                        : null,
                    ),
                    child: isSelected
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 20),
            
            // Icon selector
            Text(
              'Icon',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: FolderService.folderIcons.length,
                itemBuilder: (context, index) {
                  final iconName = FolderService.folderIcons[index];
                  final isSelected = iconName == _selectedIcon;
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = iconName),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        _getIconData(iconName),
                        color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              widget.onSave(_nameController.text, _selectedColor, _selectedIcon);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work_outline;
      case 'person':
        return Icons.person_outline;
      case 'lightbulb':
        return Icons.lightbulb_outline;
      case 'school':
        return Icons.school_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'favorite':
        return Icons.favorite_outline;
      case 'shopping_cart':
        return Icons.shopping_cart_outlined;
      case 'travel_explore':
        return Icons.travel_explore_outlined;
      case 'fitness_center':
        return Icons.fitness_center_outlined;
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'music_note':
        return Icons.music_note_outlined;
      case 'camera_alt':
        return Icons.camera_alt_outlined;
      case 'book':
        return Icons.book_outlined;
      case 'code':
        return Icons.code_outlined;
      case 'notes':
        return Icons.notes_outlined;
      default:
        return Icons.folder_outlined;
    }
  }
}