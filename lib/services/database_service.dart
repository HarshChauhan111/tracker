import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/location_model.dart';
import '../models/route_model.dart';
import '../models/geofence_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'location_tracker.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Locations table
    await db.execute('''
      CREATE TABLE locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy REAL,
        altitude REAL,
        speed REAL,
        heading REAL,
        timestamp TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0,
        routeId TEXT
      )
    ''');

    // Routes table
    await db.execute('''
      CREATE TABLE routes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT,
        name TEXT,
        totalDistance REAL DEFAULT 0,
        locationCount INTEGER DEFAULT 0,
        isActive INTEGER DEFAULT 1
      )
    ''');

    // Geofences table
    await db.execute('''
      CREATE TABLE geofences (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        radius REAL NOT NULL,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_locations_userId ON locations(userId)');
    await db.execute('CREATE INDEX idx_locations_timestamp ON locations(timestamp)');
    await db.execute('CREATE INDEX idx_locations_isSynced ON locations(isSynced)');
    await db.execute('CREATE INDEX idx_locations_routeId ON locations(routeId)');
    await db.execute('CREATE INDEX idx_routes_userId ON routes(userId)');
  }

  // ========== Location Operations ==========

  Future<int> insertLocation(LocationModel location) async {
    final db = await database;
    return await db.insert('locations', location.toMap());
  }

  Future<List<LocationModel>> getUnsyncedLocations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'locations',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => LocationModel.fromMap(maps[i]));
  }

  Future<void> markLocationsSynced(List<String> ids) async {
    final db = await database;
    await db.update(
      'locations',
      {'isSynced': 1},
      where: 'id IN (${ids.map((_) => '?').join(',')})',
      whereArgs: ids,
    );
  }

  Future<List<LocationModel>> getLocationsByDate(String userId, DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'locations',
      where: 'userId = ? AND timestamp >= ? AND timestamp < ?',
      whereArgs: [
        userId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) => LocationModel.fromMap(maps[i]));
  }

  Future<List<LocationModel>> getLocationsByRoute(String routeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'locations',
      where: 'routeId = ?',
      whereArgs: [routeId],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) => LocationModel.fromMap(maps[i]));
  }

  Future<LocationModel?> getLastLocation(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'locations',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return LocationModel.fromMap(maps.first);
  }

  Future<void> deleteOldLocations(int daysToKeep) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    await db.delete(
      'locations',
      where: 'timestamp < ? AND isSynced = ?',
      whereArgs: [cutoffDate.toIso8601String(), 1],
    );
  }

  // ========== Route Operations ==========

  Future<int> insertRoute(RouteModel route) async {
    final db = await database;
    return await db.insert('routes', route.toMap());
  }

  Future<void> updateRoute(RouteModel route) async {
    final db = await database;
    await db.update(
      'routes',
      route.toMap(),
      where: 'id = ?',
      whereArgs: [route.id],
    );
  }

  Future<RouteModel?> getActiveRoute(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'routes',
      where: 'userId = ? AND isActive = ?',
      whereArgs: [userId, 1],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return RouteModel.fromMap(maps.first);
  }

  Future<List<RouteModel>> getRoutesByDate(String userId, DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'routes',
      where: 'userId = ? AND startTime >= ? AND startTime < ?',
      whereArgs: [
        userId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: 'startTime DESC',
    );
    return List.generate(maps.length, (i) => RouteModel.fromMap(maps[i]));
  }

  Future<List<RouteModel>> getAllRoutes(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'routes',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'startTime DESC',
    );
    return List.generate(maps.length, (i) => RouteModel.fromMap(maps[i]));
  }

  // ========== Geofence Operations ==========

  Future<void> insertGeofence(GeoFence geofence) async {
    final db = await database;
    await db.insert('geofences', geofence.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<GeoFence>> getAllGeofences() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('geofences');
    return List.generate(maps.length, (i) => GeoFence.fromMap(maps[i]));
  }

  Future<List<GeoFence>> getActiveGeofences() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'geofences',
      where: 'isActive = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => GeoFence.fromMap(maps[i]));
  }

  Future<void> deleteGeofence(String id) async {
    final db = await database;
    await db.delete('geofences', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateGeofence(GeoFence geofence) async {
    final db = await database;
    await db.update(
      'geofences',
      geofence.toMap(),
      where: 'id = ?',
      whereArgs: [geofence.id],
    );
  }

  // ========== Database Maintenance ==========

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('locations');
    await db.delete('routes');
    await db.delete('geofences');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
