// lib/widgets/media_list_item.dart

// Import Flutter material design components.
import 'package:flutter/material.dart';
// Import our custom MediaFile model.
import 'package:sanad_player/models/media_file.dart';
// Import the video_thumbnail package for generating video thumbnails.
import 'package:video_thumbnail/video_thumbnail.dart';
// Import dart:io for File operations (needed to display local files).
import 'dart:io';
// Import path_provider to get temporary directory for saving thumbnails.
import 'package:path_provider/path_provider.dart';


// A custom widget to display a single media file item in a list.
// This is a StatelessWidget as it only displays data passed to it and does not manage its own internal state.
class MediaListItem extends StatelessWidget {
  // The MediaFile object containing details about the media item.
  final MediaFile mediaFile;
  // Callback function to execute when the item is tapped.
  final VoidCallback onTap;

  // Constructor for MediaListItem.
  // Requires a MediaFile object and an onTap callback.
  const MediaListItem({
    super.key,
    required this.mediaFile,
    required this.onTap,
  });

  // Helper method to format duration from milliseconds to a human-readable string (e.g., "01:23").
  String _formatDuration(int? durationMs) {
    if (durationMs == null) return "N/A"; // Return "N/A" if duration is not available.

    final duration = Duration(milliseconds: durationMs); // Convert milliseconds to Duration object.
    String twoDigits(int n) => n.toString().padLeft(2, '0'); // Helper to pad single digits with a leading zero.

    final hours = twoDigits(duration.inHours); // Get hours.
    final minutes = twoDigits(duration.inMinutes.remainder(60)); // Get remaining minutes.
    final seconds = twoDigits(duration.inSeconds.remainder(60)); // Get remaining seconds.

    // Format based on whether hours are present.
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  // Helper method to format file size from bytes to a human-readable string (e.g., "12.34 MB").
  String _formatFileSize(int fileSize) {
    if (fileSize < 1024) return '$fileSize B'; // Less than 1 KB, display in Bytes.
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(2)} KB'; // Less than 1 MB, display in KBs.
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB'; // Display in MBs.
  }

  // Helper method to generate a video thumbnail.
  // Returns the path to the thumbnail file as a Future<String?>.
  Future<String?> _getVideoThumbnail(String videoPath) async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        // Using temporaryDirectory ensures thumbnails are cleaned up by the OS eventually.
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG, // Desired format for the thumbnail.
        maxHeight: 128, // Max height of thumbnail in pixels.
        maxWidth: 128, // Max width of thumbnail in pixels.
        quality: 50, // Quality of the thumbnail (0-100).
      );
      return thumbnailPath;
    } catch (e) {
      print('Error generating thumbnail for $videoPath: $e');
      return null; // Return null if there's an error during generation.
    }
  }

  @override
  // The build method describes the user interface of this widget.
  Widget build(BuildContext context) {
    // ListTile is a convenient Material Design widget for displaying items in a list.
    return ListTile(
      // Leading widget (left side of the list tile) to display icon or thumbnail.
      leading: FutureBuilder<String?>(
        // The future determines what data to load:
        // If it's a video, generate a thumbnail. Otherwise, return null (for audio/unknown).
        future: mediaFile.type == MediaType.video
            ? _getVideoThumbnail(mediaFile.filePath) // Call our helper function to get thumbnail path.
            : Future.value(null), // For audio or other types, immediately return a resolved null Future.
        builder: (context, snapshot) {
          // Check the state of the future (loading, done, error).
          if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
            // If thumbnail is generated successfully and data is available, display it.
            return ClipRRect( // ClipRRect for rounded corners for the image.
              borderRadius: BorderRadius.circular(8.0),
              child: Image.file(
                File(snapshot.data!), // Display the thumbnail image from the generated file path.
                width: 60, // Set desired width for the thumbnail.
                height: 60, // Set desired height for the thumbnail.
                fit: BoxFit.cover, // Cover the entire allocated space.
              ),
            );
          } else {
            // Fallback: Show a default icon if thumbnail is not available,
            // or if it's still loading, or if it's an audio file.
            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface, // Use theme's surface color as background.
                borderRadius: BorderRadius.circular(8.0), // Rounded corners for the container.
              ),
              child: Icon(
                // Display movie icon for video, music icon for audio.
                mediaFile.type == MediaType.video ? Icons.movie : Icons.music_note,
                size: 30, // Size of the fallback icon.
                color: Theme.of(context).colorScheme.onSurface, // Icon color for contrast.
              ),
            );
          }
        },
      ),
      // Main title of the list item, showing the file name.
      title: Text(
        mediaFile.fileName,
        style: Theme.of(context).textTheme.titleMedium, // Apply a suitable text style from our theme.
        maxLines: 2, // Allow title to wrap to two lines if long.
        overflow: TextOverflow.ellipsis, // Truncate with ellipsis if it exceeds two lines.
      ),
      // Subtitle of the list item, displaying formatted duration and file size.
      subtitle: Text(
        '${_formatDuration(mediaFile.durationMs)} | ${_formatFileSize(mediaFile.fileSize)}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith( // Use a smaller text style from our theme.
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // Slightly transparent text.
        ),
      ),
      // Trailing icon (optional, often used for 'more options' or navigation).
      trailing: const Icon(Icons.arrow_forward_ios, size: 16), // Small arrow indicating tap action.
      // onTap callback when the list item is tapped.
      onTap: onTap,
      // Padding around the list item.
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    );
  }
}