// lib/services/permission_service.dart

// Import the permission_handler package.
// This package provides a cross-platform (Android, iOS, etc.) API to request and check permissions.
import 'package:permission_handler/permission_handler.dart';

// A service class responsible for handling application permissions.
// This centralizes all permission-related logic.
class PermissionService {
  // Requests storage permission from the user.
  // Returns true if the permission is granted, false otherwise.
  Future<bool> requestStoragePermission() async {
    // Request the storage permission.
    // On Android, this specifically requests the READ_EXTERNAL_STORAGE and WRITE_EXTERNAL_STORAGE permissions
    // (though on modern Android versions, more granular media permissions are used).
    // On iOS, it relates to media library access.
    var status = await Permission.storage.request();

    // Check the status of the permission after the request.
    if (status.isGranted) {
      // Permission has been granted.
      return true;
    } else if (status.isDenied) {
      // Permission has been denied by the user.
      // The user might be prompted again in the future.
      print('Storage permission denied.');
      return false;
    } else if (status.isPermanentlyDenied) {
      // Permission has been permanently denied.
      // This happens if the user checks "Don't ask again" or denies multiple times.
      // We should direct the user to app settings to grant the permission manually.
      print('Storage permission permanently denied. Opening settings.');
      await openAppSettings(); // Opens the app's settings page for manual permission granting.
      return false;
    } else if (status.isRestricted) {
      // Permission is restricted (e.g., due to parental controls).
      print('Storage permission restricted.');
      return false;
    } else {
      // Handles any other unexpected permission states.
      print('Unknown storage permission status: $status');
      return false;
    }
  }

  // Checks if storage permission is already granted.
  // Returns true if granted, false otherwise.
  Future<bool> checkStoragePermission() async {
    // Get the current status of the storage permission.
    var status = await Permission.storage.status;
    return status.isGranted; // Returns true if permission is granted, false otherwise.
  }
}