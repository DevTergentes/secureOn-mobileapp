import 'dart:convert';
import 'dart:io';
import 'package:fastflow_app/management/models/record.dart';
import 'package:http/http.dart' as http;

import '../models/monitoring_summary.dart';

class RecordService {
  final String baseUrl =
      "https://secureon-backend-production.up.railway.app/api/secureon/v1/records";
  final String deliveryRecordsBaseUrl =
      "https://secureon-backend-production.up.railway.app/api/secureon/v1/records/delivery";

  Future<MonitoringSummary> getMonitoringSummary(int deliveryId) async {
    try {
      // Primero intentar obtener todos los records para ver si hay datos
      List<RecordLog> allRecords = [];
      try {
        allRecords = await getAllRecords(deliveryId);
      } catch (e) {
        print('getMonitoringSummary: Error getting all records: $e');
        // Si falla, intentar obtener el latest directamente
      }
      
      RecordLog latestRecord;
      if (allRecords.isNotEmpty) {
        // Si hay records, usar el más reciente
        latestRecord = allRecords.last;
        print('getMonitoringSummary: Using latest from allRecords: ${latestRecord.timestamp}');
      } else {
        // Si no hay records, intentar obtener el latest
        try {
          latestRecord = await getLatestRecord(deliveryId);
        } catch (e) {
          print('getMonitoringSummary: No records found, creating dummy record');
          // Crear un record dummy si no hay datos
          latestRecord = RecordLog(
            sensorId: 0,
            deliveryId: deliveryId,
            timestamp: DateTime.now(),
            temperatureValue: 0.0,
            gasValue: 0.0,
            heartRateValue: 0.0,
            latitude: 0.0,
            longitude: 0.0,
          );
        }
      }
      
      // Intentar obtener el tiempo de monitoreo, pero si falla usar 0
      int monitoringMinutes = 0;
      try {
        monitoringMinutes = await getMonitoringTime(deliveryId);
      } catch (e) {
        print('getMonitoringSummary: Error getting monitoring time: $e');
        monitoringMinutes = 0;
      }
      
      // Intentar obtener el estado safe, pero si falla usar false
      bool safeStatus = false;
      try {
        safeStatus = await isSafe(deliveryId);
      } catch (e) {
        print('getMonitoringSummary: Error getting safe status: $e');
        safeStatus = false;
      }

      return MonitoringSummary(
        record: latestRecord,
        monitoringMinutes: monitoringMinutes,
        safe: safeStatus,
      );
    } catch (e) {
      print('getMonitoringSummary: Error: $e');
      throw Exception('Error loading monitoring summary: $e');
    }
  }

  Future<RecordLog> getLatestRecord(int deliveryId) async {
    final url = '$deliveryRecordsBaseUrl/$deliveryId/latest';
    print('getLatestRecord: Requesting URL: $url');
    final http.Response response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 5));
    
    print('getLatestRecord: Status code: ${response.statusCode}');
    print('getLatestRecord: Response body: ${response.body}');
    
    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = json.decode(response.body);
      print('getLatestRecord: Parsed JSON: $jsonResponse');

      try {
        final record = RecordLog.fromJson(jsonResponse);
        print('getLatestRecord: Record created successfully');
        return record;
      } catch (e) {
        print('getLatestRecord: Error parsing record: $e');
        print('getLatestRecord: JSON was: $jsonResponse');
        rethrow;
      }
    } else {
      print('getLatestRecord: HTTP error ${response.statusCode}: ${response.body}');
      throw Exception('Failed to load record details: HTTP ${response.statusCode}');
    }
  }

  Future<int> getMonitoringTime(int deliveryId) async {
    final url = '$deliveryRecordsBaseUrl/$deliveryId/timedifference';
    print('getMonitoringTime: Requesting URL: $url');
    final http.Response response = await http.get(Uri.parse(url));

    print('getMonitoringTime: Status code: ${response.statusCode}');
    print('getMonitoringTime: Response body: ${response.body}');

    if (response.statusCode == HttpStatus.ok) {
      return int.parse(response.body);
    } else {
      print('getMonitoringTime: HTTP error ${response.statusCode}: ${response.body}');
      throw Exception('Failed to load monitoring time: HTTP ${response.statusCode}');
    }
  }

  Future<bool> isSafe(int deliveryId) async {
    final url = 'https://secureon-backend-production.up.railway.app/api/secureon/v1/sensors/delivery/$deliveryId';
    print('isSafe: Requesting URL: $url');
    final http.Response response = await http.get(Uri.parse(url));

    print('isSafe: Status code: ${response.statusCode}');
    print('isSafe: Response body: ${response.body}');

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonList = json.decode(response.body);

      if (jsonList.isNotEmpty && jsonList[0] is Map<String, dynamic>) {
        final firstSensor = jsonList[0];
        return firstSensor['safe'] == true;
      } else {
        throw Exception(
            'Unexpected JSON format: expected non-empty list of objects');
      }
    } else {
      print('isSafe: HTTP error ${response.statusCode}: ${response.body}');
      throw Exception('Failed to check safety status: HTTP ${response.statusCode}');
    }
  }

  Future<List<RecordLog>> getAllRecords(int deliveryId) async {
    final url = '$deliveryRecordsBaseUrl/$deliveryId';
    print('getAllRecords: Requesting URL: $url');
    final response = await http.get(Uri.parse(url));
    
    print('getAllRecords: Status code: ${response.statusCode}');
    print('getAllRecords: Response body length: ${response.body.length}');
    
    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonList = json.decode(response.body);
      print('getAllRecords: Found ${jsonList.length} records');
      
      if (jsonList.isEmpty) {
        print('getAllRecords: No records found for delivery $deliveryId');
        return [];
      }
      
      try {
        final records = jsonList.map((json) {
          try {
            return RecordLog.fromJson(json);
          } catch (e) {
            print('getAllRecords: Error parsing record: $e');
            print('getAllRecords: Problematic JSON: $json');
            rethrow;
          }
        }).toList();
        return records;
      } catch (e) {
        print('getAllRecords: Error parsing records list: $e');
        rethrow;
      }
    } else {
      print('getAllRecords: HTTP error ${response.statusCode}: ${response.body}');
      throw Exception('Failed to load records: HTTP ${response.statusCode}');
    }
  }

  Future<void> addRecord(RecordLog record) async {
    final url = baseUrl;
    print('addRecord: Posting to URL: $url');
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode(record.toJson()),
    );

    if (response.statusCode != HttpStatus.ok && response.statusCode != HttpStatus.created) {
      print('Failed to add record. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to add record');
    }
  }
}
