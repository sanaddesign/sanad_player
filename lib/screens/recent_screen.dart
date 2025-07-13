// lib/screens/recent_screen.dart

import 'package:flutter/material.dart';
import 'package:sanad_player/models/media_file.dart';
import 'package:sanad_player/services/file_scanner_service.dart'; // To get data from DB
import 'package:sanad_player/widgets/media_list_item.dart'; // To display media files
import 'package:sanad_player/screens/video_player_screen.dart'; // For navigation
import 'package:sanad_player/screens/music_player_screen.dart'; // For navigation
// ...
import 'package:sanad_player/services/database_service.dart'; // Add this line

class RecentScreen extends StatefulWidget {
  const RecentScreen({super.key});

  @override
  State<RecentScreen> createState() => _RecentScreenState();
}

class _RecentScreenState extends State<RecentScreen> {
  List<MediaFile> _recentMedia = [];
  bool _isLoading = true;
  final FileScannerService _fileScannerService = FileScannerService();
  // ...
  final DatabaseService _databaseService = DatabaseService.instance; // Add this line
// ...
  @override
  void initState() {
    super.initState();
    _loadRecentMedia();
  }

  Future<void> _loadRecentMedia() async {
    setState(() {
      _isLoading = true;
    });
    // Get recently played media from database via FileScannerService
    // (FileScannerService now has getRecentlyPlayedMedia via DatabaseService)
    List<MediaFile> files = await _fileScannerService.getMediaFilesFromDatabase(
      mediaTypeFilter: null, // No type filter, show all recent
    );
    // Filter to only show actual played files (those with a timestamp)
    files = files.where((file) => file.lastPlayedTimestamp != null).toList();
    // Sort by timestamp in descending order (most recent first)
    files.sort((a, b) => b.lastPlayedTimestamp!.compareTo(a.lastPlayedTimestamp!));

    setState(() {
      _recentMedia = files;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recently Played'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recentMedia.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 20),
            Text(
              'No recently played media.',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadRecentMedia, // Retry loading
              child: const Text('Refresh'),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _recentMedia.length,
        itemBuilder: (context, index) {
          final mediaFile = _recentMedia[index];
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cannot play this file type!')),
                );
              }
            },
          );
        },
      ),
    );
  }
}