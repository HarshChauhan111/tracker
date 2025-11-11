import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_service.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  bool _isSyncing = false;

  // Sync locations from SQLite to Firestore
  Future<void> syncLocations() async {
    if (_isSyncing) {
      print('Sync already in progress');
      return;
    }

    try {
      _isSyncing = true;

      // Check network connectivity
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        print('No network connectivity');
        return;
      }

      // Get current user
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        print('No authenticated user');
        return;
      }

      // Get unsynced locations
      final unsyncedLocations = await _databaseService.getUnsyncedLocations();
      if (unsyncedLocations.isEmpty) {
        print('No unsynced locations');
        return;
      }

      print('Syncing ${unsyncedLocations.length} locations...');

      // Sync in batches of 500 (Firestore batch limit)
      const batchSize = 500;
      for (int i = 0; i < unsyncedLocations.length; i += batchSize) {
        final batch = unsyncedLocations.skip(i).take(batchSize).toList();
        
        try {
          await _firestoreService.saveLocationsBatch(batch);
          
          // Mark as synced in local database
          final syncedIds = batch
              .where((loc) => loc.id != null)
              .map((loc) => loc.id!)
              .toList();
          
          if (syncedIds.isNotEmpty) {
            await _databaseService.markLocationsSynced(syncedIds);
          }
          
          print('Synced batch ${(i ~/ batchSize) + 1}');
        } catch (e) {
          print('Error syncing batch: $e');
          // Continue with next batch
        }
      }

      print('Sync completed');
    } catch (e) {
      print('Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Auto sync on network change
  Stream<void> autoSync() {
    return Connectivity().onConnectivityChanged.asyncMap((_) async {
      await Future.delayed(const Duration(seconds: 2)); // Wait for stable connection
      await syncLocations();
    });
  }

  // Force sync
  Future<bool> forceSync() async {
    try {
      await syncLocations();
      return true;
    } catch (e) {
      print('Force sync failed: $e');
      return false;
    }
  }
}
