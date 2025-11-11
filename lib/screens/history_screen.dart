import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../models/location_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final MapController _mapController = MapController();
  DateTime _selectedDate = DateTime.now();
  List<LocationModel> _locations = [];
  bool _isLoading = false;
  int _playbackIndex = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoading = true);
    
    final authProvider = context.read<AuthProvider>();
    if (authProvider.firebaseUser != null) {
      final locations = await _databaseService.getLocationsByDate(
        authProvider.firebaseUser!.uid,
        _selectedDate,
      );
      setState(() {
        _locations = locations;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
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
        _playbackIndex = 0;
        _isPlaying = false;
      });
      await _loadLocations();
    }
  }

  void _startPlayback() {
    if (_locations.isEmpty) return;
    
    setState(() => _isPlaying = true);
    _playbackIndex = 0;
    
    Future.doWhile(() async {
      if (!_isPlaying || _playbackIndex >= _locations.length) {
        setState(() => _isPlaying = false);
        return false;
      }
      
      final location = _locations[_playbackIndex];
      _mapController.move(
        LatLng(location.latitude, location.longitude),
        15.0, // zoom level
      );
      
      setState(() => _playbackIndex++);
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    });
  }
  
  Future<void> _openInGoogleMaps(LatLng position) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _stopPlayback() {
    setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    // Build polyline points
    final polylinePoints = _locations
        .map((loc) => LatLng(loc.latitude, loc.longitude))
        .toList();

    // Build markers list
    final markers = <Marker>[];
    if (_playbackIndex > 0 && _playbackIndex <= _locations.length) {
      final currentLoc = _locations[_playbackIndex - 1];
      final point = LatLng(currentLoc.latitude, currentLoc.longitude);
      markers.add(
        Marker(
          point: point,
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () => _openInGoogleMaps(point),
            child: const Icon(
              Icons.location_on,
              size: 40,
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
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
                          ],
                        ),
                      )
                    : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          center: LatLng(
                            _locations.first.latitude,
                            _locations.first.longitude,
                          ),
                          zoom: 14,
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
          ),
          
          // Playback Controls
          if (_locations.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isPlaying ? _stopPlayback : _startPlayback,
                    icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                    label: Text(_isPlaying ? 'Stop' : 'Play Route'),
                  ),
                  if (_isPlaying) ...[
                    const SizedBox(width: 16),
                    Text(
                      '${_playbackIndex}/${_locations.length}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
