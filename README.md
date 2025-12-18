# MindWeave - Smart Notes with Copy Blocks

**MindWeave** is an elegant, mobile-first notes application designed for capturing thoughts, organizing ideas, and effortlessly sharing information. Its standout feature is the intuitive "Copy Block," which allows for one-tap extraction of text snippets, making it ideal for developers, writers, and students.

This project has been modernized and deployed as a Flutter Web application, showcasing a clean, responsive UI and a streamlined user experience.

---

### ✨ Live Demo

**[Access the live web demo here](https://your-vercel-link-will-go-here.vercel.app)**

*(Link will be active after deployment to Vercel)*

---

### Key Features

- **📝 Note Management**: A full suite of tools for creating, editing, and organizing your notes.
- **📋 Copy Blocks**: Special collapsible text blocks with a one-tap copy function, perfect for code snippets, quotes, or any reusable text.
- **🗂️ Folder System**: Organize your notes into folders for better categorization and quick access.
- **🔍 Quick Search**: A fast and efficient search function to find information across all your notes.
- **📱 Mobile-First UI**: A responsive design with dark mode, intuitive navigation, and smooth animations that works beautifully on both mobile and desktop browsers.

### Technical Stack

This project is built with **Flutter**, showcasing a modern, cross-platform development approach. The key technologies and libraries used are:

| Category      | Technology/Library     |
|---------------|------------------------|
| **Framework** | Flutter 3.x            |
| **Language**  | Dart 3.x               |
| **UI/Styling**| Material Design, `google_fonts` |
| **State/Storage**| `shared_preferences` for local storage |
| **Utilities** | `url_launcher`, `intl`, `uuid` |
| **Deployment**| Vercel                 |

### Project Structure

The project follows a clean architecture, separating concerns into a well-organized file structure:

```
lib/
├── main.dart              # App entry point
├── theme.dart             # Theme configuration
├── models/                # Data models (Note, Folder, CopyBlock)
├── services/              # Business logic (Notes, Folders, Storage)
├── screens/               # UI screens (Home, Editor, Folders, Search)
└── widgets/               # Reusable UI components
```

### Getting Started (Local Development)

To run this project locally, follow these steps:

1.  **Prerequisites**: Ensure you have the [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.

2.  **Clone the repository**:

    ```bash
    git clone <your-github-repo-link>
    cd mindweave_project
    ```

3.  **Install dependencies**:

    ```bash
    flutter pub get
    ```

4.  **Run the app**:

    ```bash
    flutter run -d chrome
    ```

### License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
