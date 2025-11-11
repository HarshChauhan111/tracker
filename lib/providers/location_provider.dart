import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';
import '../models/route_model.dart';
import '../models/user_model.dart';
import '../services/location_service.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';
import '../services/sync_service.dart';
import 'dart:async';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  final DatabaseService _databaseService = DatabaseService();
  final FirestoreService _firestoreService = FirestoreService();
  final SyncService _syncService = SyncService();

  bool _isTracking = false;
  Position? _currentPosition;
  RouteModel? _activeRoute;
  List<LocationModel> _todayLocations = [];
  StreamSubscription<Position>? _positionSubscription;
  String? _errorMessage;

  // Shared users tracking
  Map<String, UserModel> _sharedUsers = {};
  Map<String, LocationModel?> _sharedUsersLocations = {};
  final Map<String, StreamSubscription> _sharedLocationSubscriptions = {};
  StreamSubscription<List<UserModel>>? _sharedUsersSubscription;

  bool get isTracking => _isTracking;
  Position? get currentPosition => _currentPosition;
  RouteModel? get activeRoute => _activeRoute;
  List<LocationModel> get todayLocations => _todayLocations;
  String? get errorMessage => _errorMessage;
  Map<String, UserModel> get sharedUsers => _sharedUsers;
  Map<String, LocationModel?> get sharedUsersLocations => _sharedUsersLocations;

  Future<void> initialize(String userId) async {
    // Check if tracking was active
    _isTracking = await _locationService.isTrackingActive();
    
    // Load active route
    _activeRoute = await _databaseService.getActiveRoute(userId);
    
    // Load today's locations
    await loadTodayLocations(userId);
    
    // Start listening to shared users' locations
    startListeningToSharedLocations(userId);
    
    notifyListeners();
  }

  // Start listening to shared users and their locations
  void startListeningToSharedLocations(String myUserId) {
    // Cancel existing subscription
    _sharedUsersSubscription?.cancel();
    
    print('Starting to listen for shared locations for user: $myUserId');
    
    // Listen to users who shared with me
    _sharedUsersSubscription = _firestoreService.getUsersICanViewStream(myUserId).listen((users) {
      print('Received ${users.length} users who shared with me');
      
      final newUserIds = users.map((u) => u.uid).toSet();
      
      // Cancel subscriptions for users who no longer share
      final removedIds = _sharedLocationSubscriptions.keys.where((uid) => !newUserIds.contains(uid)).toList();
      for (final uid in removedIds) {
        print('Removing subscription for user: $uid');
        _sharedLocationSubscriptions[uid]?.cancel();
        _sharedLocationSubscriptions.remove(uid);
        _sharedUsers.remove(uid);
        _sharedUsersLocations.remove(uid);
      }
      
      // Add new subscriptions
      for (final user in users) {
        print('Processing shared user: ${user.email}');
        _sharedUsers[user.uid] = user;
        
        if (!_sharedLocationSubscriptions.containsKey(user.uid)) {
          print('Creating location subscription for: ${user.email}');
          final sub = _firestoreService.getLiveLocationStream(user.uid).listen((location) {
            print('Received location update for ${user.email}: ${location != null ? "Found" : "NULL"}');
            if (location != null) {
              print('Location: lat=${location.latitude}, lng=${location.longitude}, time=${location.timestamp}');
            }
            _sharedUsersLocations[user.uid] = location;
            notifyListeners();
          }, onError: (error) {
            print('Error listening to location for ${user.email}: $error');
          });
          _sharedLocationSubscriptions[user.uid] = sub;
        }
      }
      
      notifyListeners();
    }, onError: (error) {
      print('Error getting users I can view: $error');
    });
  }

  // Stop listening to shared users
  void stopListeningToSharedLocations() {
    _sharedUsersSubscription?.cancel();
    _sharedUsersSubscription = null;
    
    for (final sub in _sharedLocationSubscriptions.values) {
      sub.cancel();
    }
    _sharedLocationSubscriptions.clear();
    _sharedUsers.clear();
    _sharedUsersLocations.clear();
    notifyListeners();
  }

  Future<bool> startTracking(String userId) async {
    try {
      // Check permissions
      final permission = await _locationService.checkPermission();
      if (permission == LocationPermission.denied) {
        final newPermission = await _locationService.requestPermission();
        if (newPermission == LocationPermission.denied ||
            newPermission == LocationPermission.deniedForever) {
          _errorMessage = 'Location permission is required';
          notifyListeners();
          return false;
        }
      }

      // Start background tracking
      await _locationService.startBackgroundTracking(userId);
      
      // Also start foreground stream for real-time updates
      _positionSubscription = _locationService.getPositionStream().listen(
        (Position position) async {
          _currentPosition = position;
          
          // Update live location in Firestore for others to see
          try {
            final location = LocationModel(
              userId: userId,
              latitude: position.latitude,
              longitude: position.longitude,
              accuracy: position.accuracy,
              altitude: position.altitude,
              speed: position.speed,
              heading: position.heading,
              timestamp: DateTime.now(),
            );
            await _firestoreService.updateLiveLocation(location);
          } catch (e) {
            print('Error updating live location: $e');
          }
          
          notifyListeners();
        },
      );

      _isTracking = true;
      _activeRoute = await _databaseService.getActiveRoute(userId);
      
      // Update Firestore
      await _firestoreService.setTrackingEnabled(userId, true);
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> stopTracking(String userId) async {
    try {
      await _locationService.stopBackgroundTracking(userId);
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      
      _isTracking = false;
      _activeRoute = null;
      
      // Update Firestore
      await _firestoreService.setTrackingEnabled(userId, false);
      
      // Sync any remaining locations
      await _syncService.syncLocations();
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadTodayLocations(String userId) async {
    try {
      _todayLocations = await _databaseService.getLocationsByDate(
        userId,
        DateTime.now(),
      );
      notifyListeners();
    } catch (e) {
      print('Error loading today\'s locations: $e');
    }
  }

  Future<void> syncNow() async {
    try {
      await _syncService.syncLocations();
    } catch (e) {
      _errorMessage = 'Sync failed: ${e.toString()}';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    stopListeningToSharedLocations();
    super.dispose();
  }
}
