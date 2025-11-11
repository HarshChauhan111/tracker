import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class PermissionHelper {
  // Check all required permissions
  static Future<Map<String, bool>> checkAllPermissions() async {
    final locationPermission = await Geolocator.checkPermission();
    final notificationStatus = await Permission.notification.status;

    return {
      'location': locationPermission == LocationPermission.always ||
          locationPermission == LocationPermission.whileInUse,
      'locationAlways': locationPermission == LocationPermission.always,
      'notification': notificationStatus.isGranted,
    };
  }

  // Request location permission
  static Future<bool> requestLocationPermission() async {
    // Use permission_handler for more reliable permission checks
    final status = await Permission.location.status;
    
    if (status.isDenied) {
      final result = await Permission.location.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      return false;
    }
    
    return status.isGranted;
  }

  // Request background location permission (Always Allow)
  static Future<bool> requestBackgroundLocationPermission() async {
    // First ensure basic location permission
    final locationStatus = await Permission.location.status;
    if (!locationStatus.isGranted) {
      final result = await Permission.location.request();
      if (!result.isGranted) {
        return false;
      }
    }
    
    // Then request always/background permission
    final bgStatus = await Permission.locationAlways.status;
    if (!bgStatus.isGranted) {
      final result = await Permission.locationAlways.request();
      return result.isGranted;
    }
    
    return true;
  }

  // Request notification permission
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // Show permission dialog
  static Future<void> showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onOpenSettings,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              if (onOpenSettings != null) {
                onOpenSettings();
              } else {
                openAppSettings();
              }
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // Show battery optimization warning
  static Future<void> showBatteryOptimizationDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Battery Optimization'),
        content: const Text(
          'For continuous location tracking, please disable battery optimization for this app.\n\n'
          'Go to Settings > Apps > Location Tracker > Battery > Unrestricted',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // Check and request all permissions with dialogs
  static Future<bool> checkAndRequestAllPermissions(BuildContext context) async {
    // Check if location permission is already granted
    final locationStatus = await Permission.location.status;
    bool locationGranted = locationStatus.isGranted || locationStatus.isLimited;
    
    // Only request if not already granted
    if (!locationGranted) {
      locationGranted = await requestLocationPermission();
      if (!locationGranted) {
        if (context.mounted) {
          await showPermissionDialog(
            context,
            title: 'Location Permission Required',
            message: 'This app needs location permission to track your location.',
          );
        }
        return false;
      }
    }

    // Check if background location permission is already granted
    final backgroundStatus = await Permission.locationAlways.status;
    bool backgroundGranted = backgroundStatus.isGranted || backgroundStatus.isLimited;
    
    // Only request if not already granted
    if (!backgroundGranted) {
      backgroundGranted = await requestBackgroundLocationPermission();
      if (!backgroundGranted && context.mounted) {
        // Show info dialog but don't block (background permission is optional)
        await showPermissionDialog(
          context,
          title: 'Background Location',
          message: 'For continuous tracking even when the app is closed, '
              'please allow "Always" location access.',
        );
      }
    }

    // Check notification permission
    final notificationStatus = await Permission.notification.status;
    bool notificationGranted = notificationStatus.isGranted;
    
    if (!notificationGranted) {
      notificationGranted = await requestNotificationPermission();
      if (!notificationGranted && context.mounted) {
        await showPermissionDialog(
          context,
          title: 'Notification Permission',
          message: 'This app needs notification permission to show tracking status.',
        );
      }
    }

    // Show battery optimization warning only once per session
    if (context.mounted && !backgroundGranted) {
      await showBatteryOptimizationDialog(context);
    }

    return true;
  }

  // Check if location services are enabled
  static Future<bool> checkLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Prompt to enable location services
  static Future<void> promptEnableLocationServices(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Please enable location services in your device settings to use this app.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
