// lib/widgets/media_folder_item.dart

import 'package:flutter/material.dart';
import 'package:sanad_player/models/media_folder.dart';

// A custom widget to display a single media folder item in a list.
class MediaFolderItem extends StatelessWidget {
  final MediaFolder folder;
  final VoidCallback onTap;

  const MediaFolderItem({
    super.key,
    required this.folder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.folder,
        size: 40,
        color: Theme.of(context).colorScheme.secondary, // Accent color for folder icon
      ),
      title: Text(
        folder.name,
        style: Theme.of(context).textTheme.titleMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${folder.mediaCount} media files', // Display count of media files in folder
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    );
  }
}