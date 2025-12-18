# QuickNote Architecture

## Overview
QuickNote is a mobile-first notes app with unique copy block functionality. The app follows Flutter best practices with clean architecture and native UI patterns.

## Core Features (MVP)
1. **Note Management**: Create, edit, delete, organize notes
2. **Copy Blocks**: Special collapsible text blocks with one-tap copy
3. **Folder System**: Organize notes into categories
4. **Search**: Quick search across all notes
5. **Mobile-Optimized UI**: Dark mode, bottom navigation, swipe gestures

## Technical Architecture

### Data Layer
- **Local Storage**: SharedPreferences for app state and settings
- **Models**: Note, Folder, CopyBlock with JSON serialization
- **Services**: NotesService, FolderService for data operations

### UI Layer
- **Main Navigation**: Bottom navigation bar with 4 tabs
- **Screens**: Home (notes list), Editor, Folders, Search
- **Widgets**: Reusable components for notes, copy blocks, etc.

### Key Components
1. **HomePage**: Grid/list view of notes with preview
2. **NoteEditorScreen**: Full-screen editing with formatting
3. **FoldersScreen**: Manage note organization
4. **SearchScreen**: Real-time search functionality
5. **CopyBlock Widget**: Core feature - collapsible blocks with copy

### Design System
- **Primary Color**: Blue (#007AFF) - iOS system blue
- **Typography**: System fonts (SF Pro on iOS, Roboto on Android)
- **Layout**: 44pt minimum touch targets, consistent spacing
- **Animations**: Smooth transitions, micro-interactions

## File Structure
```
lib/
├── main.dart              # App entry point
├── theme.dart            # Theme configuration
├── models/              
│   ├── note.dart         # Note data model
│   ├── folder.dart       # Folder data model
│   └── copy_block.dart   # Copy block data model
├── services/
│   ├── notes_service.dart    # Notes CRUD operations
│   ├── folder_service.dart   # Folder management
│   └── storage_service.dart  # Local storage abstraction
├── screens/
│   ├── home_screen.dart      # Main notes list
│   ├── note_editor_screen.dart # Note editing
│   ├── folders_screen.dart   # Folder management
│   └── search_screen.dart    # Search functionality
└── widgets/
    ├── note_card.dart        # Note preview card
    ├── copy_block_widget.dart # Copy block component
    ├── folder_selector.dart  # Folder selection UI
    └── custom_bottom_nav.dart # Bottom navigation
```

## Technical Implementation Details

### Copy Block Feature
- Markdown-like syntax: `[BLOCK: Title] Content [/BLOCK]`
- Expandable/collapsible UI with smooth animations
- One-tap copy functionality with visual feedback
- Editor integration for easy block creation

### Mobile Optimizations
- Pull-to-refresh on notes list
- Swipe-to-delete on note cards
- Haptic feedback for interactions
- Keyboard-aware scrolling in editor
- Responsive layout for different screen sizes

### Data Persistence
- JSON serialization for complex objects
- Efficient local storage with SharedPreferences
- Automatic save/restore of editor state
- Search index for fast text queries

## Development Phases
1. **Phase 1**: Core models, services, and basic UI
2. **Phase 2**: Note editor with copy block functionality
3. **Phase 3**: Folder management and search
4. **Phase 4**: Mobile optimizations and polish
5. **Phase 5**: Testing and bug fixes