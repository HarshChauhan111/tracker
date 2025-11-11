import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/location_model.dart';
import '../models/route_model.dart';

class RouteExportService {
  // Export route to CSV
  static Future<File?> exportToCSV(
    List<LocationModel> locations,
    String fileName,
  ) async {
    try {
      // Prepare CSV data
      List<List<dynamic>> rows = [
        [
          'Timestamp',
          'Latitude',
          'Longitude',
          'Accuracy',
          'Altitude',
          'Speed',
          'Heading'
        ]
      ];

      for (var location in locations) {
        rows.add([
          location.timestamp.toIso8601String(),
          location.latitude,
          location.longitude,
          location.accuracy ?? '',
          location.altitude ?? '',
          location.speed ?? '',
          location.heading ?? '',
        ]);
      }

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(rows);

      // Get directory to save file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.csv');

      // Write to file
      await file.writeAsString(csv);

      return file;
    } catch (e) {
      print('Error exporting to CSV: $e');
      return null;
    }
  }

  // Export route to JSON
  static Future<File?> exportToJSON(
    List<LocationModel> locations,
    RouteModel? route,
    String fileName,
  ) async {
    try {
      // Prepare JSON data
      Map<String, dynamic> data = {
        'route': route != null
            ? {
                'id': route.id,
                'userId': route.userId,
                'startTime': route.startTime.toIso8601String(),
                'endTime': route.endTime?.toIso8601String(),
                'name': route.name,
                'totalDistance': route.totalDistance,
                'locationCount': route.locationCount,
              }
            : null,
        'locations': locations.map((location) {
          return {
            'timestamp': location.timestamp.toIso8601String(),
            'latitude': location.latitude,
            'longitude': location.longitude,
            'accuracy': location.accuracy,
            'altitude': location.altitude,
            'speed': location.speed,
            'heading': location.heading,
          };
        }).toList(),
      };

      // Convert to JSON string
      String jsonString = const JsonEncoder.withIndent('  ').convert(data);

      // Get directory to save file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.json');

      // Write to file
      await file.writeAsString(jsonString);

      return file;
    } catch (e) {
      print('Error exporting to JSON: $e');
      return null;
    }
  }

  // Share exported file
  static Future<void> shareFile(File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Location tracking data',
      );
    } catch (e) {
      print('Error sharing file: $e');
    }
  }

  // Export and share in one step
  static Future<bool> exportAndShare({
    required List<LocationModel> locations,
    RouteModel? route,
    required String format, // 'csv' or 'json'
    String? fileName,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final defaultFileName = fileName ?? 'route_$timestamp';

      File? file;
      if (format.toLowerCase() == 'csv') {
        file = await exportToCSV(locations, defaultFileName);
      } else if (format.toLowerCase() == 'json') {
        file = await exportToJSON(locations, route, defaultFileName);
      }

      if (file != null) {
        await shareFile(file);
        return true;
      }
      return false;
    } catch (e) {
      print('Error in exportAndShare: $e');
      return false;
    }
  }
}
