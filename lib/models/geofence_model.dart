class GeoFence {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius; // in meters
  final bool isActive;
  final DateTime createdAt;

  GeoFence({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // From Map
  factory GeoFence.fromMap(Map<String, dynamic> map) {
    return GeoFence(
      id: map['id'] as String,
      name: map['name'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      radius: map['radius'] as double,
      isActive: map['isActive'] == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  // To Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
