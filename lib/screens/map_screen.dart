import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../utils/permission_helper.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'shared_locations_screen.dart';
import 'shared_user_history_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final authProvider = context.read<AuthProvider>();
    final locationProvider = context.read<LocationProvider>();
    
    if (authProvider.firebaseUser != null) {
      await locationProvider.initialize(authProvider.firebaseUser!.uid);
    }
  }

  Future<void> _toggleTracking() async {
    final authProvider = context.read<AuthProvider>();
    final locationProvider = context.read<LocationProvider>();
    
    if (authProvider.firebaseUser == null) return;

    if (locationProvider.isTracking) {
      await locationProvider.stopTracking(authProvider.firebaseUser!.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tracking stopped')),
        );
      }
    } else {
      // Check and request permissions first
      final hasPermissions = await PermissionHelper.checkAndRequestAllPermissions(context);
      if (!hasPermissions) {
        return; // User denied permissions
      }
      
      // Check if location services are enabled
      final serviceEnabled = await PermissionHelper.checkLocationServiceEnabled();
      if (!serviceEnabled && mounted) {
        await PermissionHelper.promptEnableLocationServices(context);
        return;
      }
      
      final success = await locationProvider.startTracking(
        authProvider.firebaseUser!.uid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Tracking started'
                  : locationProvider.errorMessage ?? 'Failed to start tracking',
                  
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
          
        );
        
      }
    }
  }

  void _centerOnCurrentLocation() {
    final locationProvider = context.read<LocationProvider>();
    if (locationProvider.currentPosition != null) {
      _mapController.move(
        LatLng(
          locationProvider.currentPosition!.latitude,
          locationProvider.currentPosition!.longitude,
        ),
        16,
      );
    }
  }

  Future<void> _openInGoogleMaps(LatLng position) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showSharedUserDetails(BuildContext context, String userId) {
    final locationProvider = context.read<LocationProvider>();
    final user = locationProvider.sharedUsers[userId];
    final location = locationProvider.sharedUsersLocations[userId];

    if (user == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.red,
              child: Text(
                (user.displayName ?? user.email)[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.displayName ?? user.email.split('@')[0],
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              user.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            if (location != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Last seen: ${_formatTime(location.timestamp)}',
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Lat: ${location.latitude.toStringAsFixed(6)}, '
                'Lng: ${location.longitude.toStringAsFixed(6)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, color: Colors.grey, size: 20),
                  SizedBox(width: 8),
                  Text('Location unavailable'),
                ],
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: location != null
                      ? () {
                          Navigator.pop(context);
                          _openInGoogleMaps(
                            LatLng(location.latitude, location.longitude),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.navigation),
                  label: const Text('Navigate'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SharedUserHistoryScreen(
                          userId: userId,
                          user: user,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('View History'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();

    // Build markers for my location
    final markers = <Marker>[];
    if (locationProvider.currentPosition != null) {
      final currentPos = LatLng(
        locationProvider.currentPosition!.latitude,
        locationProvider.currentPosition!.longitude,
      );
      markers.add(
        Marker(
          point: currentPos,
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () => _openInGoogleMaps(currentPos),
            child: Column(
              children: [
                const Icon(
                  Icons.person_pin_circle,
                  size: 40,
                  color: Colors.blue,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Me',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Build markers for shared users
    for (final entry in locationProvider.sharedUsersLocations.entries) {
      final userId = entry.key;
      final location = entry.value;
      final user = locationProvider.sharedUsers[userId];
      
      if (location != null) {
        final pos = LatLng(location.latitude, location.longitude);
        markers.add(
          Marker(
            point: pos,
            width: 100,
            height: 80,
            child: GestureDetector(
              onTap: () => _openInGoogleMaps(pos),
              onLongPress: () => _showSharedUserDetails(context, userId),
              child: Column(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 40,
                    color: Colors.red,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      user?.displayName ?? user?.email.split('@')[0] ?? 'User',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    // Build polyline
    final polylinePoints = locationProvider.todayLocations
        .map((loc) => LatLng(loc.latitude, loc.longitude))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SharedLocationsScreen(),
                ),
              );
            },
            tooltip: 'Shared Locations',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryScreen(),
                ),
              );
            },
            tooltip: 'History',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Stack(
        children: [
          // OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: locationProvider.currentPosition != null
                  ? LatLng(
                      locationProvider.currentPosition!.latitude,
                      locationProvider.currentPosition!.longitude,
                    )
                  : LatLng(0, 0),
              initialZoom: locationProvider.currentPosition != null ? 15 : 2,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.tracker',
              ),
              if (polylinePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: polylinePoints,
                      strokeWidth: 4,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: markers,
              ),
            ],
          ),
          
          // Stats Card
          if (locationProvider.activeRoute != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Active Route',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat(
                            'Distance',
                            locationProvider.activeRoute!.formattedDistance,
                            Icons.route,
                          ),
                          _buildStat(
                            'Points',
                            '${locationProvider.todayLocations.length}',
                            Icons.pin_drop,
                          ),
                          _buildStat(
                            'Duration',
                            _formatDuration(
                              locationProvider.activeRoute!.duration,
                            ),
                            Icons.timer,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Center on location button
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton.small(
              onPressed: _centerOnCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleTracking,
        icon: Icon(
          locationProvider.isTracking ? Icons.stop : Icons.play_arrow,
        ),
        label: Text(
          locationProvider.isTracking ? 'Stop Tracking' : 'Start Tracking',
        ),
        backgroundColor: locationProvider.isTracking
            ? Colors.red
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
