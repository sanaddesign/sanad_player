// lib/services/file_scanner_service.dart

import 'dart:io';
import 'package:path/path.dart' as p; // Import path package for path manipulation
import 'package:path_provider/path_provider.dart';
import 'package:sanad_player/models/media_file.dart';
import 'package:sanad_player/models/media_folder.dart'; // Import MediaFolder
import 'package:sanad_player/services/database_service.dart'; // Import DatabaseService

class FileScannerService {
  final DatabaseService _databaseService = DatabaseService.instance; // Instance of DatabaseService

  final List<String> _videoExtensions = [
    'mp4', 'mkv', 'avi', 'mov', 'm4v', 'webm', 'flv', 'wmv'
  ];
  final List<String> _audioExtensions = [
    'mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a'
  ];

  // Helper to check if a file extension is a media file.
  bool _isMediaFile(String fileExtension) {
    return _videoExtensions.contains(fileExtension) || _audioExtensions.contains(fileExtension);
  }

  // Scans the device's storage for folders containing media files.
  // Returns a Future list of MediaFolder objects found.
  // After scanning, it saves the folders to the database.
  Future<List<MediaFolder>> scanMediaFolders() async {
    Map<String, MediaFolder> foundFolders = {};
    Set<String> rootDirectoriesToScan = {};

    if (Platform.isAndroid) {
      List<Directory>? externalStorageDirs = await getExternalStorageDirectories(type: StorageDirectory.documents);
      if (externalStorageDirs != null) {
        for (var dir in externalStorageDirs) {
          rootDirectoriesToScan.add(dir.path);
        }
      }
      rootDirectoriesToScan.addAll([
        '/storage/emulated/0/Download',
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0/Movies',
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Pictures',
        '/storage/emulated/0/WhatsApp/Media',
        '/storage/emulated/0/Telegram/Telegram Documents',
      ]);
    } else if (Platform.isWindows) {
      final Directory? downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        rootDirectoriesToScan.add(downloadsDir.path);
      } else {
        print('Could not find Downloads directory. Attempting common user paths.');
      }

      String userProfile = Platform.environment['USERPROFILE'] ?? '';
      if (userProfile.isNotEmpty) {
        rootDirectoriesToScan.add('$userProfile\\Downloads');
        rootDirectoriesToScan.add('$userProfile\\Videos');
        rootDirectoriesToScan.add('$userProfile\\Music');
        rootDirectoriesToScan.add('$userProfile\\Documents');
      } else {
        print('User profile path not found. Cannot add common user folders.');
      }
    } else if (Platform.isIOS) {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      rootDirectoriesToScan.add(appDocDir.path);
    } else if (Platform.isLinux || Platform.isMacOS) {
      final Directory? downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        rootDirectoriesToScan.add(downloadsDir.path);
      }
      final Directory? musicDir = await getApplicationSupportDirectory();
      if (musicDir != null) {
        rootDirectoriesToScan.add(musicDir.path);
      }
    }

    print('--- Scanning Root Directories for Media Folders: ---');
    for (String rootDirPath in rootDirectoriesToScan) {
      Directory rootDirectory = Directory(rootDirPath);
      if (await rootDirectory.exists()) {
        try {
          await for (var entity in rootDirectory.list(recursive: false, followLinks: false)) {
            if (entity is Directory) {
              int mediaCountInFolder = 0;
              await for (var fileEntity in entity.list(recursive: true, followLinks: false)) {
                if (fileEntity is File) {
                  String fileExtension = p.extension(fileEntity.path).toLowerCase().replaceAll('.', '');
                  if (_isMediaFile(fileExtension)) {
                    mediaCountInFolder++;
                  }
                }
              }
              if (mediaCountInFolder > 0) {
                final folderPath = entity.path;
                final folderName = p.basename(folderPath);
                foundFolders[folderPath] = MediaFolder(
                  path: folderPath,
                  name: folderName,
                  mediaCount: mediaCountInFolder,
                );
              }
            }
          }
        } catch (e) {
          print('Error scanning root directory ${rootDirPath}: $e');
        }
      } else {
        print('Root directory does not exist or is inaccessible: $rootDirPath');
      }
    }

    for(String path in rootDirectoriesToScan) {
      Directory dir = Directory(path);
      if (await dir.exists()) {
        int mediaCount = 0;
        await for (var entity in dir.list(recursive: false, followLinks: false)) {
          if (entity is File) {
            String fileExtension = p.extension(entity.path).toLowerCase().replaceAll('.', '');
            if (_isMediaFile(fileExtension)) {
              mediaCount++;
            }
          }
        }
        if (mediaCount > 0 && !foundFolders.containsKey(path)) {
          foundFolders[path] = MediaFolder(
            path: path,
            name: p.basename(path),
            mediaCount: mediaCount,
          );
        }
      }
    }

    print('--- Scan Complete. Found ${foundFolders.length} media folders. ---');

    // NEW: Save found folders to the database
    await _databaseService.deleteAllMediaData(); // Clear old data before saving new
    for (var folder in foundFolders.values) {
      await _databaseService.insertFolder(folder);
    }
    print('Folders saved to database.');

    return foundFolders.values.toList();
  }

  // Gets media files within a specific folder.
  // After scanning, it saves the files to the database.
  Future<List<MediaFile>> getMediaFilesInFolder(String folderPath) async {
    List<MediaFile> mediaFiles = [];
    Directory directory = Directory(folderPath);

    if (await directory.exists()) {
      await for (var entity in directory.list(recursive: false, followLinks: false)) {
        if (entity is File) {
          String filePath = entity.path;
          String fileName = p.basename(filePath);
          String fileExtension = p.extension(filePath).toLowerCase().replaceAll('.', '');

          MediaType type = MediaType.unknown;
          if (_videoExtensions.contains(fileExtension)) {
            type = MediaType.video;
          } else if (_audioExtensions.contains(fileExtension)) {
            type = MediaType.audio;
          }

          if (type != MediaType.unknown) {
            try {
              int fileSize = await entity.length();
              mediaFiles.add(MediaFile(
                id: filePath,
                filePath: filePath,
                fileName: fileName,
                type: type,
                durationMs: null,
                fileSize: fileSize,
              ));
            } catch (e) {
              print('Error getting file info for ${filePath}: $e');
            }
          }
        }
      }
    }
    // NEW: Save found media files to the database
    await _databaseService.insertMediaFilesBatch(mediaFiles); // Use batch insert for efficiency
    print('Media files in folder "$folderPath" saved to database.');
    return mediaFiles;
  }

  // Scans all common media paths for all media files (not just folders),
  // optionally filtered by media type.
  // After scanning, it saves the files to the database.
  Future<List<MediaFile>> getAllMediaFiles({MediaType? filterType}) async {
    List<MediaFile> allMediaFiles = [];
    Set<String> allScanPaths = {};

    if (Platform.isAndroid) {
      List<Directory>? externalStorageDirs = await getExternalStorageDirectories(type: StorageDirectory.documents);
      if (externalStorageDirs != null) {
        for (var dir in externalStorageDirs) {
          allScanPaths.add(dir.path);
        }
      }
      allScanPaths.addAll([
        '/storage/emulated/0/Download',
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0/Movies',
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Pictures',
        '/storage/emulated/0/WhatsApp/Media',
        '/storage/emulated/0/Telegram/Telegram Documents',
      ]);
    } else if (Platform.isWindows) {
      final Directory? downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) allScanPaths.add(downloadsDir.path);
      String userProfile = Platform.environment['USERPROFILE'] ?? '';
      if (userProfile.isNotEmpty) {
        allScanPaths.add('$userProfile\\Downloads');
        allScanPaths.add('$userProfile\\Videos');
        allScanPaths.add('$userProfile\\Music');
        allScanPaths.add('$userProfile\\Documents');
      }
    } else if (Platform.isIOS) {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      allScanPaths.add(appDocDir.path);
    } else if (Platform.isLinux || Platform.isMacOS) {
      final Directory? downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) allScanPaths.add(downloadsDir.path);
      final Directory? musicDir = await getApplicationSupportDirectory();
      if (musicDir != null) allScanPaths.add(musicDir.path);
    }

    print('--- Scanning all known paths for all media files (filtered by type: $filterType): ---');
    for (String dirPath in allScanPaths) {
      Directory directory = Directory(dirPath);
      if (await directory.exists()) {
        try {
          await for (var entity in directory.list(recursive: true, followLinks: false)) {
            if (entity is File) {
              String filePath = entity.path;
              String fileName = p.basename(filePath);
              String fileExtension = p.extension(filePath).toLowerCase().replaceAll('.', '');

              MediaType type = MediaType.unknown;
              if (_videoExtensions.contains(fileExtension)) {
                type = MediaType.video;
              } else if (_audioExtensions.contains(fileExtension)) {
                type = MediaType.audio;
              }

              if (type != MediaType.unknown && (filterType == null || type == filterType)) {
                try {
                  int fileSize = await entity.length();
                  allMediaFiles.add(MediaFile(
                    id: filePath,
                    filePath: filePath,
                    fileName: fileName,
                    type: type,
                    durationMs: null,
                    fileSize: fileSize,
                  ));
                } catch (e) {
                  print('Error getting file info for ${filePath}: $e');
                }
              }
            }
          }
        } catch (e) {
          print('Error listing directory ${dirPath}: $e');
        }
      }
    }
    print('--- Found ${allMediaFiles.length} total media files. ---');

    // NEW: Save found media files to the database
    await _databaseService.insertMediaFilesBatch(allMediaFiles); // Use batch insert for efficiency
    print('All media files saved to database.');

    return allMediaFiles.toSet().toList();
  }

  // NEW: Retrieves all media folders from the local database.
  Future<List<MediaFolder>> getFoldersFromDatabase() async {
    print('Attempting to load folders from database...');
    return await _databaseService.getFolders();
  }

  // NEW: Retrieves media files from the local database, optionally filtered by folder or type.
  Future<List<MediaFile>> getMediaFilesFromDatabase({
    String? folderPath,
    MediaType? mediaTypeFilter,
  }) async {
    print('Attempting to load media files from database...');
    if (folderPath != null && folderPath.isNotEmpty) {
      return await _databaseService.getMediaFilesFromFolder(folderPath);
    } else {
      return await _databaseService.getMediaFiles(filterType: mediaTypeFilter);
    }
  }

  // NEW: Deletes all existing data from the database.
  Future<void> clearDatabase() async {
    print('Clearing all media data from database...');
    await _databaseService.deleteAllMediaData();
  }
}