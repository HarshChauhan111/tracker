import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import '../models/location_model.dart';
import '../services/firestore_service.dart';

class SharedUserHistoryScreen extends StatefulWidget {
  final String userId;
  final UserModel user;

  const SharedUserHistoryScreen({
    super.key,
    required this.userId,
    required this.user,
  });

  @override
  State<SharedUserHistoryScreen> createState() => _SharedUserHistoryScreenState();
}

class _SharedUserHistoryScreenState extends State<SharedUserHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final MapController _mapController = MapController();
  DateTime _selectedDate = DateTime.now();
  List<LocationModel> _locations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoading = true);

    try {
      final locations = await _firestoreService.getSharedUserLocationsByDate(
        widget.userId,
        _selectedDate,
      );
      setState(() {
        _locations = locations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading locations: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadLocations();
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

  @override
  Widget build(BuildContext context) {
    // Build polyline points
    final polylinePoints = _locations
        .map((loc) => LatLng(loc.latitude, loc.longitude))
        .toList();

    // Build markers
    final markers = <Marker>[];
    if (_locations.isNotEmpty) {
      // Start marker
      final start = _locations.first;
      markers.add(
        Marker(
          point: LatLng(start.latitude, start.longitude),
          width: 60,
          height: 60,
          child: GestureDetector(
            onTap: () => _openInGoogleMaps(LatLng(start.latitude, start.longitude)),
            child: const Column(
              children: [
                Icon(Icons.play_circle, color: Colors.green, size: 40),
                Text('Start', style: TextStyle(fontSize: 10, color: Colors.green)),
              ],
            ),
          ),
        ),
      );

      // End marker
      if (_locations.length > 1) {
        final end = _locations.last;
        markers.add(
          Marker(
            point: LatLng(end.latitude, end.longitude),
            width: 60,
            height: 60,
            child: GestureDetector(
              onTap: () => _openInGoogleMaps(LatLng(end.latitude, end.longitude)),
              child: const Column(
                children: [
                  Icon(Icons.stop_circle, color: Colors.red, size: 40),
                  Text('End', style: TextStyle(fontSize: 10, color: Colors.red)),
                ],
              ),
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.user.displayName ?? widget.user.email.split('@')[0]}\'s History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
            tooltip: 'Select Date',
          ),
        ],
      ),
      body: Column(
        children: [
          // Date and Stats
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.edit_calendar, size: 18),
                        label: const Text('Change'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_locations.length} location points recorded',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (_locations.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat(
                          'Distance',
                          _calculateDistance(),
                          Icons.route,
                        ),
                        _buildStat(
                          'Duration',
                          _calculateDuration(),
                          Icons.timer,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Map
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _locations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No location data for this date',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'They may not have been tracking on this date',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      )
                    : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: LatLng(
                            _locations.first.latitude,
                            _locations.first.longitude,
                          ),
                          initialZoom: 14,
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
                                  color: Colors.blue,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: markers,
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _calculateDistance() {
    if (_locations.length < 2) return '0 km';

    double totalDistance = 0;
    for (int i = 0; i < _locations.length - 1; i++) {
      final distance = Distance().as(
        LengthUnit.Meter,
        LatLng(_locations[i].latitude, _locations[i].longitude),
        LatLng(_locations[i + 1].latitude, _locations[i + 1].longitude),
      );
      totalDistance += distance;
    }

    if (totalDistance < 1000) {
      return '${totalDistance.toStringAsFixed(0)} m';
    } else {
      return '${(totalDistance / 1000).toStringAsFixed(2)} km';
    }
  }

  String _calculateDuration() {
    if (_locations.length < 2) return '0m';

    final duration = _locations.last.timestamp.difference(_locations.first.timestamp);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
