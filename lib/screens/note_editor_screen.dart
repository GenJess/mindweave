import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindweave/models/note.dart';
import 'package:mindweave/models/copy_block.dart';
import 'package:mindweave/services/notes_service.dart';
import 'package:mindweave/services/folder_service.dart';
import 'package:mindweave/services/ai_service.dart';
import 'package:mindweave/widgets/copy_block_widget.dart';
import 'package:mindweave/widgets/expandable_fab.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;

  const NoteEditorScreen({
    super.key,
    this.note,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final NotesService _notesService = NotesService();
  final FolderService _folderService = FolderService();
  final AIService _aiService = AIService();
  
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late Note _currentNote;
  
  bool _hasUnsavedChanges = false;
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note ?? Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '',
      content: '',
    );
    _titleController = TextEditingController(text: _currentNote.title);
    _contentController = TextEditingController(text: _currentNote.content);
    
    _titleController.addListener(_onContentChanged);
    _contentController.addListener(_onContentChanged);
    
    // Auto-focus title if it's a new note
    if (_currentNote.title == 'Untitled' && _currentNote.content.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _titleController.text.length,
        );
      });
    }
  }

  @override
  void dispose() {
    _saveNote();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
    
    // Auto-save after 2 seconds of inactivity
    Future.delayed(const Duration(seconds: 2), () {
      if (_hasUnsavedChanges) {
        _saveNote();
      }
    });
  }

  Future<void> _saveNote() async {
    if (!_hasUnsavedChanges) return;
    
    // Parse copy blocks from content
    final parsedBlocks = _notesService.parseCopyBlocksFromContent(_contentController.text);
    
    // Merge with existing copy blocks that aren't in content
    final allBlocks = <CopyBlock>[];
    allBlocks.addAll(_currentNote.copyBlocks);
    
    for (final parsedBlock in parsedBlocks) {
      final existingIndex = allBlocks.indexWhere((block) => 
        block.content == parsedBlock.content);
      if (existingIndex == -1) {
        allBlocks.add(parsedBlock);
      }
    }

    final title = _titleController.text.isEmpty ? 'Untitled' : _titleController.text;
    final content = _contentController.text;

    // Check if this is a new note or existing note
    final existingNote = _notesService.getNoteById(_currentNote.id);
    
    if (existingNote == null) {
      // Create new note
      print('Creating new note with title: $title');
      final newNote = await _notesService.createNote(
        title: title,
        content: content,
        folderId: _currentNote.folderId,
        tags: _currentNote.tags,
      );
      _currentNote = newNote.copyWith(copyBlocks: allBlocks);
    } else {
      // Update existing note
      print('Updating existing note: ${existingNote.id}');
      final updatedNote = _currentNote.copyWith(
        title: title,
        content: content,
        copyBlocks: allBlocks,
        modifiedAt: DateTime.now(),
      );

      await _notesService.updateNote(updatedNote);
      _currentNote = updatedNote;
    }
    
    if (mounted) {
      setState(() => _hasUnsavedChanges = false);
    }
  }

  void _addCopyBlock() {
    showDialog(
      context: context,
      builder: (context) => _CopyBlockDialog(
        onAdd: (title, content) {
          final newBlock = CopyBlock(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: content,
          );
          
          setState(() {
            _currentNote = _currentNote.copyWith(
              copyBlocks: [..._currentNote.copyBlocks, newBlock],
            );
            _hasUnsavedChanges = true;
          });
          
          // Also add to content as markdown
          final blockText = '\n\n[BLOCK: $title]\n$content\n[/BLOCK]';
          _contentController.text += blockText;
        },
      ),
    );
  }

  void _toggleCopyBlock(CopyBlock block, bool isExpanded) {
    final updatedBlock = block.copyWith(isExpanded: isExpanded);
    final updatedBlocks = _currentNote.copyBlocks.map((b) {
      return b.id == block.id ? updatedBlock : b;
    }).toList();
    
    setState(() {
      _currentNote = _currentNote.copyWith(copyBlocks: updatedBlocks);
    });
  }

  void _editCopyBlock(CopyBlock block) {
    showDialog(
      context: context,
      builder: (context) => _CopyBlockDialog(
        initialContent: block.content,
        onAdd: (title, content) {
          final updatedBlock = block.copyWith(content: content);
          final updatedBlocks = _currentNote.copyBlocks.map((b) {
            return b.id == block.id ? updatedBlock : b;
          }).toList();
          
          setState(() {
            _currentNote = _currentNote.copyWith(copyBlocks: updatedBlocks);
            _hasUnsavedChanges = true;
          });
        },
      ),
    );
  }

  void _deleteCopyBlock(CopyBlock block) {
    setState(() {
      _currentNote = _currentNote.copyWith(
        copyBlocks: _currentNote.copyBlocks.where((b) => b.id != block.id).toList(),
      );
      _hasUnsavedChanges = true;
    });
  }

  void _changeFolderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _folderService.folders.map((folder) {
            final isSelected = folder.id == _currentNote.folderId;
            return ListTile(
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(int.parse(folder.color.substring(1), radix: 16) + 0xFF000000),
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(folder.name),
              trailing: isSelected ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() {
                  _currentNote = _currentNote.copyWith(folderId: folder.id);
                  _hasUnsavedChanges = true;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_folderService.getFolderName(_currentNote.folderId)),
        actions: [
          // Folder selector
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            onPressed: _changeFolderDialog,
            tooltip: 'Change folder',
          ),
          

          
          // More options
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _shareNote();
                  break;
                case 'delete':
                  _deleteNote();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, size: 18),
                    SizedBox(width: 12),
                    Text('Share'),
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
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar showing save state
          if (_hasUnsavedChanges)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Saving...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Title
                  TextField(
                    controller: _titleController,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Note title...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    textInputAction: TextInputAction.next,
                    maxLines: null,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Copy blocks
                  if (_currentNote.copyBlocks.isNotEmpty) ...[
                    ...(_currentNote.copyBlocks.map((block) => CopyBlockWidget(
                      copyBlock: block,
                      isExpanded: block.isExpanded,
                      onUpdate: (updatedBlock) => _toggleCopyBlock(block, updatedBlock.isExpanded),
                      onDelete: () => _deleteCopyBlock(block),
                    ))),
                    const SizedBox(height: 16),
                  ],
                  
                  // Content
                  TextField(
                    controller: _contentController,
                    style: theme.textTheme.bodyLarge,
                    decoration: const InputDecoration(
                      hintText: 'Start typing your note...\n\nTip: Use [BLOCK: Title] Content [/BLOCK] to create copy blocks',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                  ),
                  
                  // Extra space for keyboard
                  SizedBox(height: _isKeyboardVisible ? 200 : 50),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Expandable floating action button with enhanced options
      floatingActionButton: _isKeyboardVisible ? null : ExpandableFab(
        distance: 80,
        actions: [
          ActionButton(
            onPressed: _addCopyBlock,
            icon: const Icon(Icons.content_copy),
            tooltip: 'Add Copy Block',
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
          ),
          ActionButton(
            onPressed: _addVariableBlock,
            icon: const Icon(Icons.dynamic_form),
            tooltip: 'Add Variable Block',
            backgroundColor: const Color(0xFFF59E0B).withOpacity(0.2),
            foregroundColor: const Color(0xFFF59E0B),
          ),
          ActionButton(
            onPressed: _autoFormat,
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Auto Format',
            backgroundColor: const Color(0xFF6366F1).withOpacity(0.2),
            foregroundColor: const Color(0xFF6366F1),
          ),
          ActionButton(
            onPressed: _chatWithAI,
            icon: const Icon(Icons.smart_toy),
            tooltip: 'Chat with AI',
            backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
            foregroundColor: const Color(0xFF10B981),
          ),
          ActionButton(
            onPressed: _uploadThread,
            icon: const Icon(Icons.upload_file),
            tooltip: 'Upload Thread',
            backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.2),
            foregroundColor: const Color(0xFF8B5CF6),
          ),
          ActionButton(
            onPressed: _addFileMedia,
            icon: const Icon(Icons.attachment),
            tooltip: 'Add File/Media',
            backgroundColor: const Color(0xFFEC4899).withOpacity(0.2),
            foregroundColor: const Color(0xFFEC4899),
          ),
        ],
        child: const Icon(Icons.blur_circular_rounded),
      ),
    );
  }

  void _addAIInsight() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Generating AI insight...'),
          ],
        ),
      ),
    );

    // Simulate AI processing
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      
      // Add AI-generated insight as a copy block
      final aiInsight = '''AI Insight: This note contains ${_currentNote.content.split(' ').length} words and covers topics related to productivity and note-taking. Key themes include organization and information management.

Suggestions:
• Consider adding tags for better organization
• Break down long paragraphs for readability
• Add action items if applicable''';

      final newBlock = CopyBlock(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: aiInsight,
      );
      
      setState(() {
        _currentNote = _currentNote.copyWith(
          copyBlocks: [..._currentNote.copyBlocks, newBlock],
        );
        _hasUnsavedChanges = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI insight added to your note'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _togglePin() {
    setState(() {
      _currentNote = _currentNote.copyWith(isPinned: !_currentNote.isPinned);
      _hasUnsavedChanges = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_currentNote.isPinned ? 'Note pinned' : 'Note unpinned'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareNote() {
    final shareText = '''${_currentNote.title}

${_currentNote.content}

${_currentNote.copyBlocks.map((block) => block.content).join('\n\n')}

Created with QuickNote''';
    
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addVariableBlock() {
    showDialog(
      context: context,
      builder: (context) => _VariableBlockDialog(
        onAdd: (template, variables) {
          // Create a variable block note or add to existing note
          final blockContent = template;
          setState(() {
            _contentController.text += '\n\n--- Variable Block ---\n$blockContent\n';
            _hasUnsavedChanges = true;
          });
        },
      ),
    );
  }

  void _autoFormat() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add some content first to auto-format'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('AI is formatting your content...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final formattedContent = await _aiService.formatContent(_contentController.text);
      
      setState(() {
        _contentController.text = formattedContent;
        _hasUnsavedChanges = true;
      });

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content formatted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to format content: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _chatWithAI() {
    showDialog(
      context: context,
      builder: (context) => _AIChatDialog(
        noteContent: _contentController.text,
        onInsertResponse: (response) {
          setState(() {
            _contentController.text += '\n\n--- AI Response ---\n$response\n';
            _hasUnsavedChanges = true;
          });
        },
      ),
    );
  }

  void _uploadThread() {
    showDialog(
      context: context,
      builder: (context) => _UploadThreadDialog(
        onProcessedThread: (formattedThread) {
          setState(() {
            _contentController.text += '\n\n--- Chat Thread ---\n$formattedThread\n';
            _hasUnsavedChanges = true;
          });
        },
      ),
    );
  }

  void _addFileMedia() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('From Gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text('Upload File'),
              onTap: () => Navigator.pop(context, 'file'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      // Handle file selection based on result
      setState(() {
        _contentController.text += '\n\n[File attachment: $result]\n';
        _hasUnsavedChanges = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$result attachment added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _deleteNote() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${_currentNote.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _notesService.deleteNote(_currentNote.id);
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close editor
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
}

class _VariableBlockDialog extends StatefulWidget {
  final Function(String template, Map<String, String> variables) onAdd;

  const _VariableBlockDialog({
    required this.onAdd,
  });

  @override
  State<_VariableBlockDialog> createState() => _VariableBlockDialogState();
}

class _VariableBlockDialogState extends State<_VariableBlockDialog> {
  final TextEditingController _templateController = TextEditingController();
  final Map<String, String> _variables = {};

  @override
  void dispose() {
    _templateController.dispose();
    super.dispose();
  }

  void _extractVariables() {
    final text = _templateController.text;
    final regex = RegExp(r'\{\{(\w+)\}\}');
    final matches = regex.allMatches(text);
    
    setState(() {
      _variables.clear();
      for (final match in matches) {
        final variable = match.group(1)!;
        if (!_variables.containsKey(variable)) {
          _variables[variable] = '';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Variable Block',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create reusable templates with variables like {{name}}, {{project}}, etc.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _templateController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Template',
                hintText: 'Hi {{name}}, I love your {{project}} idea...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) => _extractVariables(),
            ),
            
            if (_variables.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Variables:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ..._variables.keys.map((key) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: key,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                  ),
                  onChanged: (value) => _variables[key] = value,
                ),
              )),
            ],
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onAdd(_templateController.text, _variables);
                    Navigator.pop(context);
                  },
                  child: const Text('Add Block'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AIChatDialog extends StatefulWidget {
  final String noteContent;
  final Function(String response) onInsertResponse;

  const _AIChatDialog({
    required this.noteContent,
    required this.onInsertResponse,
  });

  @override
  State<_AIChatDialog> createState() => _AIChatDialogState();
}

class _AIChatDialogState extends State<_AIChatDialog> {
  final TextEditingController _questionController = TextEditingController();
  final AIService _aiService = AIService();
  String? _aiResponse;
  bool _isLoading = false;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  void _askAI() async {
    if (_questionController.text.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _aiResponse = null;
    });

    try {
      final response = await _aiService.chatAboutNote(
        widget.noteContent,
        _questionController.text,
      );
      
      setState(() {
        _aiResponse = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _aiResponse = 'Error: Failed to get AI response - $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Chat with AI',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                labelText: 'Ask AI about your note',
                hintText: 'What does this mean? Summarize this. Improve this...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  onPressed: _isLoading ? null : _askAI,
                  icon: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                ),
              ),
              onSubmitted: (_) => _askAI(),
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: _aiResponse == null && !_isLoading
                    ? Text(
                        'Ask AI anything about your note...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      )
                    : _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            child: Text(
                              _aiResponse!,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                if (_aiResponse != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      widget.onInsertResponse(_aiResponse!);
                      Navigator.pop(context);
                    },
                    child: const Text('Insert Response'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadThreadDialog extends StatefulWidget {
  final Function(String formattedThread) onProcessedThread;

  const _UploadThreadDialog({
    required this.onProcessedThread,
  });

  @override
  State<_UploadThreadDialog> createState() => _UploadThreadDialogState();
}

class _UploadThreadDialogState extends State<_UploadThreadDialog> {
  final TextEditingController _threadController = TextEditingController();
  final AIService _aiService = AIService();
  bool _isProcessing = false;

  @override
  void dispose() {
    _threadController.dispose();
    super.dispose();
  }

  void _processThread() async {
    if (_threadController.text.trim().isEmpty) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final formattedThread = await _aiService.formatChatThread(_threadController.text);
      
      widget.onProcessedThread(formattedThread);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thread processed and added'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process thread: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.upload_file, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Upload Thread',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Paste chat logs or conversation threads. AI will format them into readable chat bubbles.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: TextField(
                controller: _threadController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  labelText: 'Chat Thread',
                  hintText: 'Paste your chat logs here (JSON or plain text)...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isProcessing ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _processThread,
                  child: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Process Thread'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CopyBlockDialog extends StatefulWidget {
  final Function(String title, String content) onAdd;
  final String? initialTitle;
  final String? initialContent;

  const _CopyBlockDialog({
    required this.onAdd,
    this.initialTitle,
    this.initialContent,
  });

  @override
  State<_CopyBlockDialog> createState() => _CopyBlockDialogState();
}

class _CopyBlockDialogState extends State<_CopyBlockDialog> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController = TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text(widget.initialTitle != null ? 'Edit Copy Block' : 'Add Copy Block'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Block title',
              hintText: 'e.g., API Key, Password, Code Snippet',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: 'Content to copy',
              hintText: 'Enter the text you want to copy quickly',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty || _contentController.text.isNotEmpty) {
              widget.onAdd(
                _titleController.text.isEmpty ? 'Untitled Block' : _titleController.text,
                _contentController.text,
              );
              Navigator.pop(context);
            }
          },
          child: Text(widget.initialTitle != null ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}