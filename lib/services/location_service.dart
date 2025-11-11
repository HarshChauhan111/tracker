import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart';
import 'package:background_locator_2/background_locator.dart';
import 'package:background_locator_2/location_dto.dart';
import 'package:background_locator_2/settings/android_settings.dart';
import 'package:background_locator_2/settings/ios_settings.dart';
import 'package:background_locator_2/settings/locator_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../models/location_model.dart';
import '../models/route_model.dart';
import 'database_service.dart';
import 'sync_service.dart';
import 'firestore_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final DatabaseService _databaseService = DatabaseService();
  static const String _portName = 'location_tracker_port';
  ReceivePort? _port;

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await geo.Geolocator.isLocationServiceEnabled();
  }

  // Check location permission
  Future<geo.LocationPermission> checkPermission() async {
    return await geo.Geolocator.checkPermission();
  }

  // Request location permission
  Future<geo.LocationPermission> requestPermission() async {
    return await geo.Geolocator.requestPermission();
  }

  // Get current position
  Future<geo.Position> getCurrentPosition() async {
    return await geo.Geolocator.getCurrentPosition(
      desiredAccuracy: geo.LocationAccuracy.high,
    );
  }

  // Initialize background locator
  Future<void> startBackgroundTracking(String userId) async {
    // Verify permissions are granted (should be handled before calling this method)
    final locationStatus = await Permission.location.status;
    if (!locationStatus.isGranted && !locationStatus.isLimited) {
      throw Exception('Location permission is required for tracking. Please grant permission first.');
    }
    
    // Also verify geolocator permission
    final permission = await checkPermission();
    if (permission == geo.LocationPermission.denied ||
        permission == geo.LocationPermission.deniedForever) {
      throw Exception('Location permission is required for tracking. Please grant permission first.');
    }

    // Save userId to SharedPreferences for background callback
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);

    // Create or get active route
    RouteModel? activeRoute = await _databaseService.getActiveRoute(userId);
    if (activeRoute == null) {
      final routeId = await _databaseService.insertRoute(
        RouteModel(
          userId: userId,
          startTime: DateTime.now(),
          name: 'Route ${DateTime.now().toString().split('.')[0]}',
        ),
      );
      await prefs.setString('activeRouteId', routeId.toString());
    } else {
      await prefs.setString('activeRouteId', activeRoute.id.toString());
    }

    // Register port for communication
    if (_port != null) {
      _port!.close();
    }
    _port = ReceivePort();
    IsolateNameServer.removePortNameMapping(_portName);
    IsolateNameServer.registerPortWithName(_port!.sendPort, _portName);

    _port!.listen((dynamic data) {
      // Handle location updates from background
      print('Location update received: $data');
    });

    // Configure background locator
    await BackgroundLocator.initialize();

    // Final verification that we have at least basic location permission
    // Don't request again - just verify
    final locationPermission = await Permission.location.status;
    final locationAlwaysPermission = await Permission.locationAlways.status;
    
    if (!locationPermission.isGranted && !locationPermission.isLimited &&
        !locationAlwaysPermission.isGranted && !locationAlwaysPermission.isLimited) {
      throw Exception('Location permission denied. Please grant location access in app settings.');
    }

    await BackgroundLocator.registerLocationUpdate(
      LocationCallbackHandler.callback,
      initCallback: LocationCallbackHandler.initCallback,
      disposeCallback: LocationCallbackHandler.disposeCallback,
      iosSettings: IOSSettings(
        accuracy: LocationAccuracy.NAVIGATION,
        distanceFilter: 10.0,
        showsBackgroundLocationIndicator: true,
      ),
      androidSettings: AndroidSettings(
        accuracy: LocationAccuracy.NAVIGATION,
        interval: 30,
        distanceFilter: 10,
        client: LocationClient.google,
        androidNotificationSettings: AndroidNotificationSettings(
          notificationChannelName: 'Location Tracking',
          notificationTitle: 'Tracker',
          notificationMsg: 'Tracking your location',
          notificationBigMsg: 'Your location is being tracked continuously',
        ),
      ),
    );

    // Also register WorkManager for periodic sync
    await _registerWorkManager();
  }

  // Stop background tracking
  Future<void> stopBackgroundTracking(String userId) async {
    await BackgroundLocator.unRegisterLocationUpdate();

    // Close active route
    final activeRoute = await _databaseService.getActiveRoute(userId);
    if (activeRoute != null) {
      final updatedRoute = activeRoute.copyWith(
        endTime: DateTime.now(),
        isActive: false,
      );
      await _databaseService.updateRoute(updatedRoute);
    }

    // Clean up
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('activeRouteId');

    if (_port != null) {
      IsolateNameServer.removePortNameMapping(_portName);
      _port!.close();
      _port = null;
    }
  }

  // Check if tracking is active
  Future<bool> isTrackingActive() async {
    return await BackgroundLocator.isServiceRunning();
  }

  // Register WorkManager for periodic sync
  Future<void> _registerWorkManager() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    await Workmanager().registerPeriodicTask(
      'location_sync_task',
      'syncLocations',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  // Cancel WorkManager tasks
  Future<void> cancelWorkManager() async {
    await Workmanager().cancelAll();
  }

  // Get location stream (foreground)
  Stream<geo.Position> getPositionStream() {
    return geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  // Calculate distance between two points (in meters)
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return geo.Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  // Check if location is inside geofence
  bool isInsideGeofence(
    double lat,
    double lng,
    double centerLat,
    double centerLng,
    double radius,
  ) {
    final distance = calculateDistance(lat, lng, centerLat, centerLng);
    return distance <= radius;
  }
}

// Background callback handler
class LocationCallbackHandler {
  static Future<void> initCallback(Map<dynamic, dynamic> params) async {
    print('Background location tracking initialized');
  }

  static Future<void> disposeCallback() async {
    print('Background location tracking disposed');
  }

  static Future<void> callback(LocationDto locationDto) async {
    print('Location callback: ${locationDto.latitude}, ${locationDto.longitude}');

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final routeId = prefs.getString('activeRouteId');

      if (userId == null) {
        print('UserId not found in SharedPreferences');
        return;
      }

      // Save location to SQLite
      final location = LocationModel(
        userId: userId,
        latitude: locationDto.latitude,
        longitude: locationDto.longitude,
        accuracy: locationDto.accuracy,
        altitude: locationDto.altitude,
        speed: locationDto.speed,
        heading: locationDto.heading,
        timestamp: DateTime.now(),
        routeId: routeId,
      );

      final databaseService = DatabaseService();
      await databaseService.insertLocation(location);

      // Update live location in Firestore immediately
      try {
        final firestoreService = FirestoreService();
        await firestoreService.updateLiveLocation(location);
      } catch (e) {
        print('Error updating live location: $e');
      }

      // Try to sync all locations if online
      try {
        final syncService = SyncService();
        await syncService.syncLocations();
      } catch (e) {
        print('Sync failed, will retry later: $e');
      }

      // Send to main isolate
      final SendPort? send = IsolateNameServer.lookupPortByName(
        LocationService._portName,
      );
      send?.send(locationDto.toJson());
    } catch (e) {
      print('Error in location callback: $e');
    }
  }
}

// WorkManager callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('WorkManager task: $task');

    try {
      if (task == 'syncLocations') {
        final syncService = SyncService();
        await syncService.syncLocations();
      }
      return Future.value(true);
    } catch (e) {
      print('WorkManager task failed: $e');
      return Future.value(false);
    }
  });
}
