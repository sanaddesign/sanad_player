// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sanad_player/providers/theme_provider.dart';
import 'package:sanad_player/utils/constants.dart';
import 'package:sanad_player/screens/media_list_screen.dart'; // Used for Video/Music lists
import 'package:sanad_player/screens/settings_screen.dart'; // Settings screen
import 'package:sanad_player/screens/folder_browser_screen.dart'; // Home tab content (folder view)
import 'package:sanad_player/screens/ai_editor_screen.dart';   // AI Editor screen
import 'package:sanad_player/screens/smart_tools_screen.dart'; // Smart Tools screen

import 'package:file_picker/file_picker.dart'; // For import functionality
import 'package:sanad_player/models/media_file.dart'; // To create MediaFile objects from picked files
import 'dart:async';

import 'download_screen.dart'; // For Timer functionality (for debouncing)


// HomeScreen is a StatefulWidget as it manages the state of the selected tab
// in the Bottom Navigation Bar, and the visibility of the search bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

// State class for HomeScreen.
class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Index for Bottom Navigation Bar

  bool _isSearching = false; // Flag to control search bar visibility
  final TextEditingController _searchController = TextEditingController(); // Controller for search input
  String _searchQuery = ''; // Current search query
  Timer? _debounceTimer; // Timer for debouncing search input

  // Define acceptable media file extensions directly in HomeScreen for import functionality.
  final List<String> _videoExtensions = [
    'mp4', 'mkv', 'avi', 'mov', 'm4v', 'webm', 'flv', 'wmv'
  ];
  final List<String> _audioExtensions = [
    'mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a'
  ];

  // List of widgets (screens) corresponding to the Bottom Navigation Bar items.
  // Order matters and should match the order of BottomNavigationBarItem.
  // These widgets will be built dynamically based on the current search query.
  late final List<Widget> _children;

  @override
  void initState() {
    super.initState();
    // Initialize _children here so it can use _searchQuery.
    // These will be rebuilt by setState when _searchQuery changes.
    _children = [
      FolderBrowserScreen(searchQuery: _searchQuery), // Index 0: Home tab - shows folders
      MediaListScreen(mediaTypeFilter: MediaType.video, searchQuery: _searchQuery), // Index 1: Videos tab - show only videos
      MediaListScreen(mediaTypeFilter: MediaType.audio, searchQuery: _searchQuery), // Index 2: Music tab - show only audios
      const AiEditorScreen(),      // Index 3: AI Editor tab
      const SmartToolsScreen(),    // Index 4: Smart Tools tab
      // Index 5 for 'More' (Settings) is handled by navigation in _onItemTapped.
    ];

    _searchController.addListener(() { // Listen for changes in search input.
      // Cancel any existing timer to reset the debounce period.
      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
      // Start a new timer. The search will only trigger if no new input for 500ms.
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        // Only update state if the query has actually changed to avoid unnecessary rebuilds.
        if (_searchQuery != _searchController.text) {
          setState(() {
            _searchQuery = _searchController.text;
            // Update _children with new search query to rebuild relevant screens.
            // This will trigger didUpdateWidget in FolderBrowserScreen/MediaListScreen.
            _children[0] = FolderBrowserScreen(searchQuery: _searchQuery);
            _children[1] = MediaListScreen(mediaTypeFilter: MediaType.video, searchQuery: _searchQuery);
            _children[2] = MediaListScreen(mediaTypeFilter: MediaType.audio, searchQuery: _searchQuery);
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose(); // Dispose the controller.
    _debounceTimer?.cancel(); // Cancel the debounce timer.
    super.dispose();
  }

  // Asynchronous method to open a file picker for the "Import" functionality.
  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        ..._videoExtensions,
        ..._audioExtensions,
      ],
      allowMultiple: true,
    );

    if (result != null) {
      // For now, just show a confirmation. In a real app, these files
      // would be added to a persistent list/database.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Picked ${result.files.length} files. (Import functionality to be fully implemented)')),
      );
      print('Files picked:');
      for (var file in result.files) {
        print(file.path);
        // TODO: Add these picked files to a global list or database
        // and trigger a rebuild of the relevant media lists.
      }
    } else {
      print('File picking cancelled.');
    }
  }

  // Method to handle item taps on the Bottom Navigation Bar.
  void _onItemTapped(int index) {
    // Handle specific actions for 'More' (Settings) directly.
    if (index == 5) { // Index 5 for 'More' (Settings)
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
    } else { // For Home, Videos, Music, AI Editor, Smart Tools
      setState(() {
        _selectedIndex = index; // Update the currently selected index.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher( // Use AnimatedSwitcher for smooth transition of title/search bar.
          duration: const Duration(milliseconds: 300),
          child: _isSearching
              ? TextField( // Search bar TextField when _isSearching is true.
            key: const ValueKey('searchField'), // Unique key for AnimatedSwitcher.
            controller: _searchController,
            autofocus: true, // Focus on search bar automatically.
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
              border: InputBorder.none, // No border.
              prefixIcon: Icon(Icons.search, color: Theme.of(context).inputDecorationTheme.prefixIconColor),
              suffixIcon: IconButton( // Clear search button.
                icon: Icon(Icons.clear, color: Theme.of(context).iconTheme.color), // Use theme icon color.
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _isSearching = false; // Hide search bar.
                  });
                },
              ),
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface), // Use onSurface color for text.
            cursorColor: Theme.of(context).colorScheme.secondary, // Accent color for cursor.
          )
              : Text( // Default app title when not searching.
            appName,
            key: const ValueKey('appTitle'), // Unique key.
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
        ),
        centerTitle: false, // Align title to the left.
        actions: [
          // Search icon (toggles search bar visibility).
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear(); // Clear search when hiding.
                }
              });
            },
            tooltip: 'Search',
          ),
          // Playlists icon.
          IconButton(
            icon: const Icon(Icons.playlist_play),
            onPressed: () {
              print('Playlists icon tapped');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Playlists feature coming soon!')),
              );
              // TODO: Navigate to Playlists screen.
            },
            tooltip: 'Playlists',
          ),
          // Recent/History icon.
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              print('Recent icon tapped');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recent files feature coming soon!')),
              );
              // TODO: Navigate to Recent files screen.
            },
            tooltip: 'Recent',
          ),
          // Download/Stream icon.
          IconButton(
            icon: const Icon(Icons.cloud_download),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const DownloadScreen()));
            },
            tooltip: 'Download / Stream',
          ),
          // Share/File Transfer icon.
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              print('Share icon tapped');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share files feature coming soon!')),
              );
              // TODO: Implement file sharing logic.
            },
            tooltip: 'Share Files',
          ),
        ],
      ),
      // The body now displays the currently selected screen from _children list.
      body: _children[_selectedIndex], // Display the selected screen based on bottom nav index.

      // Bottom Navigation Bar.
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.folder), // Home/Browser (showing folders)
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.videocam), // Videos
            label: 'Videos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.audiotrack), // Music
            label: 'Music',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome), // AI Editor
            label: 'AI Editor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.handyman), // Smart Tools
            label: 'Smart Tools',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings), // More (Settings)
            label: 'More',
          ),
        ],
        currentIndex: _selectedIndex, // Currently selected item.
        selectedItemColor: Theme.of(context).colorScheme.primary, // Primary color for selected item.
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // Faded for unselected.
        backgroundColor: Theme.of(context).colorScheme.surface, // Surface color for background.
        onTap: _onItemTapped, // Call _onItemTapped when an item is tapped.
        type: BottomNavigationBarType.fixed, // Ensures all items are visible and evenly spaced.
        selectedFontSize: 12, // Adjust font size for selected label.
        unselectedFontSize: 10, // Adjust font size for unselected label.
        // Optional: iconSize, selectedLabelStyle, etc.
      ),
    );
  }
}
