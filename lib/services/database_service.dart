// lib/services/database_service.dart

// Import sqflite for database operations.
import 'package:sqflite/sqflite.dart';
// Import path for database path manipulation.
import 'package:path/path.dart';
// Import our data models for type safety.
import 'package:sanad_player/models/media_folder.dart';
import 'package:sanad_player/models/media_file.dart';

// DatabaseService is responsible for managing the SQLite database.
class DatabaseService {
  // Static instance of the database to ensure only one instance is open.
  static Database? _database;
  // Static instance of DatabaseService itself (Singleton pattern).
  static final DatabaseService instance = DatabaseService._constructor();

  // Private constructor for singleton pattern.
  DatabaseService._constructor();

  // Getter to provide the database instance.
  Future<Database> get database async {
    if (_database != null) return _database!;
    // If database is null, initialize it.
    _database = await _initDatabase();
    return _database!;
  }

  // Initializes the database: opens it, or creates it if it doesn't exist.
  Future<Database> _initDatabase() async {
    // Get the default databases location.
    String documentsDirectory = await getDatabasesPath();
    String path = join(documentsDirectory, 'sanad_player.db'); // Database file name.

    // Open the database.
    return await openDatabase(
      path,
      version: 1, // Database version.
      onCreate: _onCreate, // Called when the database is created for the first time.
      onUpgrade: _onUpgrade, // Called when the database needs to be upgraded.
    );
  }

  // Callback function to create tables when the database is first created.
  Future<void> _onCreate(Database db, int version) async {
    // Create 'folders' table.
    await db.execute('''
      CREATE TABLE folders(
        path TEXT PRIMARY KEY,
        name TEXT,
        mediaCount INTEGER
      )
    ''');
    // Create 'media_files' table with new columns.
    await db.execute('''
      CREATE TABLE media_files(
        id TEXT PRIMARY KEY,
        filePath TEXT,
        fileName TEXT,
        type TEXT,
        durationMs INTEGER,
        fileSize INTEGER,
        lastPlayedTimestamp INTEGER, -- NEW: For storing last played time (Unix timestamp in milliseconds)
        isFavorite INTEGER DEFAULT 0 -- NEW: For favorite status (0 for false, 1 for true)
      )
    ''');
    print('Database tables created: folders and media_files');
  }

  // Callback function to handle database upgrades (e.g., adding new columns/tables).
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration logic for future database version changes can go here.
    // For this project, if we change schema, we might drop and recreate for simplicity
    // or implement proper ALTER TABLE statements.
    print('Database upgraded from version $oldVersion to $newVersion');
    // Example: if you add new columns in a new version, you'd do:
    // if (oldVersion < 2) {
    //   await db.execute("ALTER TABLE media_files ADD COLUMN newColumn TEXT");
    // }
  }

  // --- CRUD Operations for MediaFolder ---
  Future<int> insertFolder(MediaFolder folder) async {
    final db = await database;
    return await db.insert('folders', folder.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MediaFolder>> getFolders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('folders');
    return List.generate(maps.length, (i) {
      return MediaFolder.fromMap(maps[i]);
    });
  }

  Future<int> deleteFolder(String path) async {
    final db = await database;
    return await db.delete(
      'folders',
      where: 'path = ?',
      whereArgs: [path],
    );
  }

  // --- CRUD Operations for MediaFile ---
  Future<int> insertMediaFile(MediaFile mediaFile) async {
    final db = await database;
    return await db.insert('media_files', mediaFile.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Insert multiple media files in a batch for efficiency.
  Future<void> insertMediaFilesBatch(List<MediaFile> mediaFiles) async {
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var file in mediaFiles) {
        batch.insert('media_files', file.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  // Get all media files from the database, optionally filtered by type.
  Future<List<MediaFile>> getMediaFiles({MediaType? filterType}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (filterType != null) {
      maps = await db.query(
        'media_files',
        where: 'type = ?',
        whereArgs: [filterType.toString().split('.').last],
      );
    } else {
      maps = await db.query('media_files');
    }
    return List.generate(maps.length, (i) {
      return MediaFile.fromMap(maps[i]);
    });
  }

  // Get media files from a specific folder (by filtering filePath).
  Future<List<MediaFile>> getMediaFilesFromFolder(String folderPath) async {
    final db = await database;
    // Use LIKE to find files whose path starts with the folderPath and a path separator.
    final List<Map<String, dynamic>> maps = await db.query(
      'media_files',
      where: 'filePath LIKE ?',
      whereArgs: ['${folderPath}%'], // Matches paths starting with folderPath
    );
    return List.generate(maps.length, (i) {
      return MediaFile.fromMap(maps[i]);
    });
  }

  // NEW: Updates a media file's favorite status.
  Future<int> updateMediaFavoriteStatus(String id, bool isFavorite) async {
    final db = await database;
    return await db.update(
      'media_files',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.replace, // Use replace to ensure update
    );
  }

  // NEW: Updates a media file's last played timestamp.
  Future<int> updateMediaLastPlayed(String id, int timestamp) async {
    final db = await database;
    return await db.update(
      'media_files',
      {'lastPlayedTimestamp': timestamp},
      where: 'id = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.replace, // Use replace to ensure update
    );
  }

  // NEW: Retrieves recently played media files (ordered by timestamp).
  Future<List<MediaFile>> getRecentlyPlayedMedia({int limit = 50}) async { // Increased limit
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'media_files',
      where: 'lastPlayedTimestamp IS NOT NULL', // Only include files that have been played
      orderBy: 'lastPlayedTimestamp DESC', // Order by most recent
      limit: limit, // Limit the number of results
    );
    return List.generate(maps.length, (i) {
      return MediaFile.fromMap(maps[i]);
    });
  }

  // NEW: Retrieves favorite media files.
  Future<List<MediaFile>> getFavoriteMedia() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'media_files',
      where: 'isFavorite = 1', // Only include files marked as favorite
      orderBy: 'fileName ASC', // Order alphabetically
    );
    return List.generate(maps.length, (i) {
      return MediaFile.fromMap(maps[i]);
    });
  }

  Future<void> deleteAllMediaData() async {
    final db = await database;
    await db.delete('folders');
    await db.delete('media_files');
    print('All media data deleted from database.');
  }
}
