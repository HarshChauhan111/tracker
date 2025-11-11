import 'package:flutter/material.dart';
import '../models/geofence_model.dart';
import '../services/location_service.dart';
import '../services/database_service.dart';

class GeofenceService with ChangeNotifier {
  final LocationService _locationService = LocationService();
  final DatabaseService _databaseService = DatabaseService();

  List<GeoFence> _geofences = [];
  final Map<String, bool> _insideGeofences = {};

  List<GeoFence> get geofences => _geofences;

  Future<void> loadGeofences() async {
    _geofences = await _databaseService.getActiveGeofences();
    notifyListeners();
  }

  Future<void> addGeofence(GeoFence geofence) async {
    await _databaseService.insertGeofence(geofence);
    await loadGeofences();
  }

  Future<void> removeGeofence(String id) async {
    await _databaseService.deleteGeofence(id);
    await loadGeofences();
  }

  Future<void> updateGeofence(GeoFence geofence) async {
    await _databaseService.updateGeofence(geofence);
    await loadGeofences();
  }

  // Check if a location is inside any geofence
  void checkGeofences(double latitude, double longitude, Function(String, bool) onStateChange) {
    for (var geofence in _geofences) {
      if (!geofence.isActive) continue;

      final isInside = _locationService.isInsideGeofence(
        latitude,
        longitude,
        geofence.latitude,
        geofence.longitude,
        geofence.radius,
      );

      final wasInside = _insideGeofences[geofence.id] ?? false;

      if (isInside != wasInside) {
        _insideGeofences[geofence.id] = isInside;
        onStateChange(geofence.name, isInside);
      }
    }
  }

  // Get distance to a geofence center
  double getDistanceToGeofence(
    double latitude,
    double longitude,
    GeoFence geofence,
  ) {
    return _locationService.calculateDistance(
      latitude,
      longitude,
      geofence.latitude,
      geofence.longitude,
    );
  }
}
