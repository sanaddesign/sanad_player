// lib/models/media_file.dart

// Define an enumeration for media types.
// This helps us clearly distinguish between video and audio files.
enum MediaType {
  video,   // Represents a video file.
  audio,   // Represents an audio file.
  unknown, // Represents a file type that is not recognized or yet to be determined.
}

// A data model representing a media file (video or audio) found on the device.
// This class holds all relevant information about a media item.
class MediaFile {
  // Unique identifier for the media file.
  // For simplicity, we'll use the filePath as the ID for now.
  // If a database is used later, a unique database ID might be generated.
  final String id;

  // The full absolute path to the media file on the device's storage.
  final String filePath;

  // The display name of the media file, extracted from its path (e.g., "My Favorite Song.mp3").
  final String fileName;

  // The type of the media file, categorized using the MediaType enum (video, audio, or unknown).
  final MediaType type;

  // The duration of the media file in milliseconds.
  // This is nullable (?) because duration might not be available for all file types
  // or might not be extractable for certain files.
  final int? durationMs;

  // The size of the media file in bytes.
  final int fileSize;

  // NEW: Timestamp when the file was last played (for Recent feature). Null if never played.
  final int? lastPlayedTimestamp;
  // NEW: Whether the file is marked as favorite (for Favorites feature). Default is false.
  final bool isFavorite;

  // Constructor for the MediaFile class.
  // All parameters are marked 'required' to ensure essential information is always provided.
  MediaFile({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.type,
    this.durationMs, // Optional parameter
    required this.fileSize,
    this.lastPlayedTimestamp, // NEW: Add to constructor
    this.isFavorite = false, // NEW: Add to constructor with default false
  });

  // Factory constructor to create a MediaFile object from a Map.
  // This is particularly useful when loading data from a database or a JSON source,
  // as data is often retrieved in a Map format.
  factory MediaFile.fromMap(Map<String, dynamic> map) {
    return MediaFile(
      id: map['id'] as String,
      filePath: map[
      'filePath'] as String,
      fileName: map['fileName'] as String,
      // Convert the string representation of MediaType back to the enum value.
      type: MediaType.values.firstWhere(
            (e) => e.toString().split('.').last == map['type'],
        orElse: () => MediaType.unknown,
      ),
      durationMs: map['durationMs'] as int?,
      fileSize: map['fileSize'] as int,
      lastPlayedTimestamp: map['lastPlayedTimestamp'] as int?, // NEW: Read from map
      isFavorite: (map['isFavorite'] as int) == 1, // NEW: Read from map (SQLite stores bool as 0 or 1)
    );
  }

  // Method to convert a MediaFile object to a Map.
  // This is useful when saving data to a database or JSON.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filePath': filePath,
      'fileName': fileName,
      'type': type.toString().split('.').last, // Store enum as string (e.g., "video", "audio")
      'durationMs': durationMs,
      'fileSize': fileSize,
      'lastPlayedTimestamp': lastPlayedTimestamp, // NEW: Write to map
      'isFavorite': isFavorite ? 1 : 0, // NEW: Write to map (store bool as 1 or 0)
    };
  }

  // NEW: Creates a copy of this MediaFile object with updated properties.
  // This is useful for updating specific fields without modifying the original immutable object.
  MediaFile copyWith({
    String? id,
    String? filePath,
    String? fileName,
    MediaType? type,
    int? durationMs,
    int? fileSize,
    int? lastPlayedTimestamp,
    bool? isFavorite,
  }) {
    return MediaFile(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      type: type ?? this.type,
      durationMs: durationMs ?? this.durationMs,
      fileSize: fileSize ?? this.fileSize,
      lastPlayedTimestamp: lastPlayedTimestamp ?? this.lastPlayedTimestamp,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  String toString() {
    return 'MediaFile(id: $id, fileName: $fileName, type: $type, duration: ${durationMs ?? 'N/A'}ms, size: $fileSize bytes, lastPlayed: $lastPlayedTimestamp, fav: $isFavorite)';
  }
}
