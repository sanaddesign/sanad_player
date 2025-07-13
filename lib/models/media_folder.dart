// lib/models/media_folder.dart

// A data model representing a folder that contains media files.
class MediaFolder {
  // The full path to the folder on the device's storage.
  final String path;
  // The display name of the folder (e.g., "Downloads", "Camera Roll").
  final String name;
  // The number of media files found within this folder.
  final int mediaCount;

  // Constructor for the MediaFolder class.
  const MediaFolder({
    required this.path,
    required this.name,
    this.mediaCount = 0, // Default count to 0 if not provided.
  });

  // Factory constructor to create a MediaFolder object from a Map (useful for database).
  factory MediaFolder.fromMap(Map<String, dynamic> map) {
    return MediaFolder(
      path: map['path'] as String,
      name: map['name'] as String,
      mediaCount: map['mediaCount'] as int,
    );
  }

  // Method to convert a MediaFolder object to a Map (useful for database).
  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'name': name,
      'mediaCount': mediaCount,
    };
  }

  @override
  String toString() {
    return 'MediaFolder(path: $path, name: $name, mediaCount: $mediaCount)';
  }
}