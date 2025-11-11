import 'package:cloud_firestore/cloud_firestore.dart';

class LocationModel {
  final String? id;
  final String userId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime timestamp;
  final bool isSynced;
  final String? routeId; // Group locations into routes/sessions

  LocationModel({
    this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    DateTime? timestamp,
    this.isSynced = false,
    this.routeId,
  }) : timestamp = timestamp ?? DateTime.now();

  // From SQLite
  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      id: map['id']?.toString(),
      userId: map['userId'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      accuracy: map['accuracy'] as double?,
      altitude: map['altitude'] as double?,
      speed: map['speed'] as double?,
      heading: map['heading'] as double?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isSynced: map['isSynced'] == 1,
      routeId: map['routeId'] as String?,
    );
  }

  // To SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
      'timestamp': timestamp.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'routeId': routeId,
    };
  }

  // From Firestore
  factory LocationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return LocationModel(
      id: doc.id,
      userId: data['userId'] as String,
      latitude: data['latitude'] as double,
      longitude: data['longitude'] as double,
      accuracy: data['accuracy'] as double?,
      altitude: data['altitude'] as double?,
      speed: data['speed'] as double?,
      heading: data['heading'] as double?,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isSynced: true,
      routeId: data['routeId'] as String?,
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
      'timestamp': Timestamp.fromDate(timestamp),
      'routeId': routeId,
    };
  }

  // Copy with
  LocationModel copyWith({
    String? id,
    String? userId,
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
    DateTime? timestamp,
    bool? isSynced,
    String? routeId,
  }) {
    return LocationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      timestamp: timestamp ?? this.timestamp,
      isSynced: isSynced ?? this.isSynced,
      routeId: routeId ?? this.routeId,
    );
  }
}
