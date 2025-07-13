// lib/screens/folder_browser_screen.dart

import 'package:flutter/material.dart';
import 'package:sanad_player/models/media_folder.dart';
import 'package:sanad_player/services/file_scanner_service.dart';
import 'package:sanad_player/services/permission_service.dart';
import 'package:sanad_player/widgets/media_folder_item.dart';
import 'package:sanad_player/screens/media_list_screen.dart';

// FolderBrowserScreen is a StatefulWidget to manage the list of folders and loading state.
class FolderBrowserScreen extends StatefulWidget {
  final String searchQuery; // Search query parameter to filter folders based on user input.

  const FolderBrowserScreen({super.key, this.searchQuery = ''});

  @override
  _FolderBrowserScreenState createState() => _FolderBrowserScreenState();
}

class _FolderBrowserScreenState extends State<FolderBrowserScreen> {
  List<MediaFolder> _mediaFolders = [];
  bool _isLoading = true;
  bool _permissionGranted = false;
  // Flag to track if it's the very first load for this screen instance.
  // This helps decide whether to try loading from DB first.
  bool _isFirstLoadForInstance = true;

  final PermissionService _permissionService = PermissionService();
  final FileScannerService _fileScannerService = FileScannerService();

  @override
  void initState() {
    super.initState();
    // On initial load, try to load from DB. If DB is empty, it will trigger a full scan.
    _checkAndScanFolders(forceRescan: false);
  }

  @override
  void didUpdateWidget(covariant FolderBrowserScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-scan or re-filter if the searchQuery changes.
    // When searchQuery changes, we always try to load from DB first to re-filter quickly.
    if (widget.searchQuery != oldWidget.searchQuery) {
      _checkAndScanFolders(forceRescan: false);
    }
  }

  // Asynchronous method to check permissions and scan/load folders.
  // forceRescan: if true, it will always perform a full file system scan and update DB.
  //              If false, it will try to load from DB first.
  Future<void> _checkAndScanFolders({bool forceRescan = false}) async {
    setState(() {
      _isLoading = true;
      _permissionGranted = false;
    });

    bool granted = await _permissionService.checkStoragePermission();
    if (!granted) {
      granted = await _permissionService.requestStoragePermission();
    }

    if (granted) {
      setState(() {
        _permissionGranted = true;
      });

      List<MediaFolder> folders = [];
      // Attempt to load from database first if not forcing a rescan
      // AND if it's the first time this instance is loading (to avoid unnecessary DB reads on every update).
      if (!forceRescan && _isFirstLoadForInstance) {
        folders = await _fileScannerService.getFoldersFromDatabase();
        if (folders.isNotEmpty) {
          print('FolderBrowserScreen: Folders loaded from database.');
        }
      }

      // If database was empty for this view, or forceRescan is true, perform a full scan.
      if (folders.isEmpty || forceRescan) {
        print('FolderBrowserScreen: Performing full scan for folders...');
        // Clear database before a full rescan to ensure fresh data.
        if (forceRescan) { // Only clear if explicitly forcing a rescan
          await _fileScannerService.clearDatabase();
          print('FolderBrowserScreen: Database cleared for full rescan.');
        }
        folders = await _fileScannerService.scanMediaFolders(); // This method now saves to DB
      }

      // After first load attempt (whether from DB or full scan), set flag to false.
      // Subsequent updates will rely on didUpdateWidget for search filtering.
      _isFirstLoadForInstance = false;

      // Apply search filter to the fetched folders.
      List<MediaFolder> filteredFolders = folders.where((folder) {
        if (widget.searchQuery.isEmpty) return true; // Show all if no query
        return folder.name.toLowerCase().contains(widget.searchQuery.toLowerCase());
      }).toList();

      setState(() {
        _mediaFolders = filteredFolders;
        _isLoading = false;
      });
    } else {
      setState(() {
        _permissionGranted = false;
        _isLoading = false;
      });
      print("FolderBrowserScreen: Permission not granted. Cannot scan for folders.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                _permissionGranted ? 'Scanning for media folders...' : 'Requesting storage permission...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        )
            : !_permissionGranted
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.storage, size: 80, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(height: 20),
              Text(
                'Storage permission is required to find media folders.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _checkAndScanFolders(forceRescan: true), // Request permission and force scan
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        )
            : _mediaFolders.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_open, size: 80, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(height: 20),
              Text(
                'No media folders found on your device.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _checkAndScanFolders(forceRescan: true), // Retry scan
                child: const Text('Retry Scan'),
              ),
            ],
          ),
        )
            : ListView.builder(
          itemCount: _mediaFolders.length,
          itemBuilder: (context, index) {
            final folder = _mediaFolders[index];
            return MediaFolderItem(
              folder: folder,
              onTap: () {
                print('Tapped on folder: ${folder.name}');
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MediaListScreen(
                      folderPath: folder.path,
                      mediaTypeFilter: null, // No type filter when browsing specific folder
                      searchQuery: '', // Clear search when navigating into folder
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
