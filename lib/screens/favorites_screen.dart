// lib/screens/favorites_screen.dart

import 'package:flutter/material.dart';
import 'package:sanad_player/models/media_file.dart';
import 'package:sanad_player/services/file_scanner_service.dart'; // To get data from DB
import 'package:sanad_player/widgets/media_list_item.dart'; // To display media files
import 'package:sanad_player/screens/video_player_screen.dart'; // For navigation
import 'package:sanad_player/screens/music_player_screen.dart'; // For navigation


class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<MediaFile> _favoriteMedia = [];
  bool _isLoading = true;
  final FileScannerService _fileScannerService = FileScannerService();

  @override
  void initState() {
    super.initState();
    _loadFavoriteMedia();
  }

  Future<void> _loadFavoriteMedia() async {
    setState(() {
      _isLoading = true;
    });
    // Get favorite media from database via FileScannerService
    // (FileScannerService now has getFavoriteMedia via DatabaseService)
    List<MediaFile> files = await _fileScannerService.getMediaFilesFromDatabase(
      mediaTypeFilter: null, // No type filter, show all favorites
    );
    // Filter to only show actual favorite files
    files = files.where((file) => file.isFavorite).toList();

    setState(() {
      _favoriteMedia = files;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteMedia.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, size: 80, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 20),
            Text(
              'No favorite media. Tap the heart icon on a media item to add it here.',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadFavoriteMedia, // Retry loading
              child: const Text('Refresh'),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _favoriteMedia.length,
        itemBuilder: (context, index) {
          final mediaFile = _favoriteMedia[index];
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