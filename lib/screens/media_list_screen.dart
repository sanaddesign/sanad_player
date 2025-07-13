// lib/screens/media_list_screen.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sanad_player/models/media_file.dart';
import 'package:sanad_player/services/file_scanner_service.dart';
import 'package:sanad_player/services/permission_service.dart';
import 'package:provider/provider.dart';
import 'package:sanad_player/providers/theme_provider.dart';
import 'package:sanad_player/widgets/media_list_item.dart';
import 'package:sanad_player/screens/video_player_screen.dart';
import 'package:sanad_player/screens/music_player_screen.dart';


class MediaListScreen extends StatefulWidget {
  final String? folderPath; // Optional folderPath parameter.
  final MediaType? mediaTypeFilter; // Optional mediaTypeFilter parameter.
  final String searchQuery; // Search query parameter.

  const MediaListScreen({
    super.key,
    this.folderPath,
    this.mediaTypeFilter,
    this.searchQuery = '',
  });

  @override
  _MediaListScreenState createState() => _MediaListScreenState();
}

class _MediaListScreenState extends State<MediaListScreen> {
  List<MediaFile> _mediaFiles = [];
  bool _isLoading = true;
  bool _permissionGranted = false;
  // Flag to track if it's the very first load for this screen instance.
  bool _isFirstLoadForInstance = true;

  final PermissionService _permissionService = PermissionService();
  final FileScannerService _fileScannerService = FileScannerService();

  final List<String> _videoExtensions = [
    'mp4', 'mkv', 'avi', 'mov', 'm4v', 'webm', 'flv', 'wmv'
  ];
  final List<String> _audioExtensions = [
    'mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a'
  ];

  @override
  void initState() {
    super.initState();
    // On initial load, try to load from DB. If DB is empty, it will trigger a full scan.
    _checkAndScanMedia(forceRescan: false);
  }

  @override
  void didUpdateWidget(covariant MediaListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-scan or re-filter if any relevant parameter changes.
    if (widget.folderPath != oldWidget.folderPath ||
        widget.mediaTypeFilter != oldWidget.mediaTypeFilter ||
        widget.searchQuery != oldWidget.searchQuery) {
      _checkAndScanMedia(forceRescan: false);
    }
  }

  // Asynchronous method to orchestrate permission checking and media scanning/loading.
  // forceRescan: if true, it will always perform a full file system scan and update DB.
  //              If false, it will try to load from DB first.
  Future<void> _checkAndScanMedia({bool forceRescan = false}) async {
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

      List<MediaFile> files = [];
      // Attempt to load from database first if not forcing a rescan
      // AND if it's the first time this instance is loading.
      if (!forceRescan && _isFirstLoadForInstance) {
        files = await _fileScannerService.getMediaFilesFromDatabase(
          folderPath: widget.folderPath,
          mediaTypeFilter: widget.mediaTypeFilter,
        );
        if (files.isNotEmpty) {
          print('MediaListScreen: Media files loaded from database for this view.');
        }
      }

      // If database was empty for this view, or forceRescan is true, perform a full scan.
      if (files.isEmpty || forceRescan) {
        print('MediaListScreen: Performing full scan for media files for this view...');
        // Clear database before a full rescan if it's a global scan (no specific folder)
        if (forceRescan && widget.folderPath == null) { // Only clear if explicitly forcing a global rescan
          await _fileScannerService.clearDatabase();
          print('MediaListScreen: Database cleared for full rescan.');
        }

        if (widget.folderPath != null && widget.folderPath!.isNotEmpty) {
          files = await _fileScannerService.getMediaFilesInFolder(widget.folderPath!); // This method saves to DB
        } else {
          files = await _fileScannerService.getAllMediaFiles(filterType: widget.mediaTypeFilter); // This method saves to DB
        }
      }

      // After first load attempt, set flag to false.
      _isFirstLoadForInstance = false;

      // Apply search filter to the fetched files.
      List<MediaFile> filteredFiles = files.where((file) {
        if (widget.searchQuery.isEmpty) return true; // Show all if no query
        return file.fileName.toLowerCase().contains(widget.searchQuery.toLowerCase());
      }).toList();

      setState(() {
        _mediaFiles = filteredFiles;
        _isLoading = false;
      });
    } else {
      setState(() {
        _permissionGranted = false;
        _isLoading = false;
      });
      print("MediaListScreen: Permission not granted.");
    }
  }

  // Asynchronous method to open a file picker and let the user select media files.
  Future<void> _pickFiles() async {
    // This method is now likely called from HomeScreen's AppBar.
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        ..._videoExtensions,
        ..._audioExtensions,
      ],
      allowMultiple: true,
    );

    if (result != null) {
      List<MediaFile> pickedMediaFiles = [];
      for (PlatformFile platformFile in result.files) {
        if (platformFile.path != null) {
          String filePath = platformFile.path!;
          String fileName = platformFile.name;
          String fileExtension = fileName.split('.').last.toLowerCase();

          MediaType type = MediaType.unknown;
          if (_videoExtensions.contains(fileExtension)) {
            type = MediaType.video;
          } else if (_audioExtensions.contains(fileExtension)) {
            type = MediaType.audio;
          }

          if (type != MediaType.unknown) {
            pickedMediaFiles.add(MediaFile(
              id: filePath,
              filePath: filePath,
              fileName: fileName,
              type: type,
              durationMs: null, // Duration is not extracted by file_picker, so set to null.
              fileSize: platformFile.size, // File size from platformFile
            ));
          }
        }
      }

      setState(() {
        _mediaFiles.addAll(pickedMediaFiles);
        _mediaFiles = _mediaFiles.toSet().toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${pickedMediaFiles.length} new files!')),
      );
    } else {
      print('File picking cancelled.');
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
                _permissionGranted ? 'Scanning for media files...' : 'Requesting storage permission...',
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
                'Storage permission is required to find media files.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _checkAndScanMedia(forceRescan: true), // Request permission and force scan
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        )
            : _mediaFiles.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_open, size: 80, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(height: 20),
              Text(
                // Text changes based on whether it's a folder scan or global filter.
                widget.folderPath != null && widget.folderPath!.isNotEmpty
                    ? 'No media files found in this folder.'
                    : 'No media files found.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _checkAndScanMedia(forceRescan: true), // Retry scan
                child: const Text('Retry Scan'),
              ),
            ],
          ),
        )
            : ListView.builder(
          itemCount: _mediaFiles.length,
          itemBuilder: (context, index) {
            final mediaFile = _mediaFiles[index];
            return MediaListItem(
              mediaFile: mediaFile,
              onTap: () {
                if (mediaFile.type == MediaType.video) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => VideoPlayerScreen(videoFile: mediaFile),
                    ),
                  );
                } else if (mediaFile.type == MediaType.audio) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MusicPlayerScreen(audioFile: mediaFile),
                    ),
                  );
                } else {
                  print('Tapped on unknown file type: ${mediaFile.fileName}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cannot play this file type!')),
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
}
