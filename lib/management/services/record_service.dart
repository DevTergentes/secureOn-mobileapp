import 'dart:convert';
import 'dart:io';
import 'package:fastflow_app/management/models/record.dart';
import 'package:http/http.dart' as http;

import '../models/monitoring_summary.dart';

class RecordService {
  final String baseUrl = "https://chemtrack-backend-production.up.railway.app/api/safeflow/v1/records/delivery";

  Future<MonitoringSummary> getMonitoringSummary(int deliveryId) async {
    try {
      final latestRecord = await getLatestRecord(deliveryId);
      final monitoringMinutes = await getMonitoringTime(deliveryId);

      final safeStatus = await isSafe(deliveryId);

      return MonitoringSummary(
        record: latestRecord,
        monitoringMinutes: monitoringMinutes,
        safe: safeStatus,
      );
    } catch (e) {
      throw Exception('Error loading monitoring summary: $e');
    }
  }

  Future<RecordLog> getLatestRecord(int deliveryId) async {
    final http.Response response = await http.get(Uri.parse('$baseUrl/$deliveryId/latest')).timeout(const Duration(seconds: 5));;
    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = json.decode(response.body);

      try {
        final record = RecordLog.fromJson(jsonResponse);
        return record;
      } catch (e, stack) {
        rethrow;
      }

    } else {
      throw Exception('Failed to load record details');
    }
  }

  Future<int> getMonitoringTime(int deliveryId) async {
    final http.Response response = await http.get(Uri.parse('$baseUrl/$deliveryId/timedifference'));

    if (response.statusCode == HttpStatus.ok) {
      return int.parse(response.body);
    } else {
      throw Exception('Failed to load monitoring time');
    }
  }

  Future<bool> isSafe(int deliveryId) async {

    final http.Response response = await http.get(
        Uri.parse('https://chemtrack-backend-production.up.railway.app/api/safeflow/v1/sensors/delivery/$deliveryId'));

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonList = json.decode(response.body);

      if (jsonList.isNotEmpty && jsonList[0] is Map<String, dynamic>) {
        final firstSensor = jsonList[0];
        return firstSensor['safe'] == true;
      } else {
        throw Exception('Unexpected JSON format: expected non-empty list of objects');
      }
    } else {
      throw Exception('Failed to check safety status');
    }
  }

  Future<List<RecordLog>> getAllRecords(int deliveryId) async {
    final response = await http.get(Uri.parse('$baseUrl/$deliveryId'));
    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => RecordLog.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load records');
    }
  }

}