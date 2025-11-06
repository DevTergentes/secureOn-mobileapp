import 'dart:convert';
import 'dart:io';
import 'package:fastflow_app/management/models/sensor.dart';
import 'package:http/http.dart' as http;

class SensorService {
  final String baseUrl = "https://secureon-backend-production.up.railway.app/api/secureon/v1/sensors";

  Future<List<Sensor>> getAllSensors() async {
    final http.Response response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Sensor.fromJson(data)).toList();
    } else {
      print('getAllSensors: HTTP ${response.statusCode} body=${response.body}');
      throw Exception('Failed to load sensors');
    }
  }

  Future<Sensor> getSensorById(int id) async {
    final http.Response response = await http.get(Uri.parse('$baseUrl/$id'));

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = json.decode(response.body);
      return Sensor.fromJson(jsonResponse);
    } else {
      print('getSensorById: HTTP ${response.statusCode} body=${response.body}');
      throw Exception('Failed to load sensor');
    }
  }

  Future<Sensor> addSensor(Sensor sensor) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode(sensor.toJson()),
    );

    if (response.statusCode == HttpStatus.ok || response.statusCode == HttpStatus.created) {
      final jsonResponse = json.decode(response.body);
      return Sensor.fromJson(jsonResponse);
    } else {
      print('addSensor: HTTP ${response.statusCode} body=${response.body}');
      throw Exception('Failed to add sensor');
    }
  }

  Future<Sensor> updateSensor(int id, Sensor sensor) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(sensor.toJson()),
    );

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = json.decode(response.body);
      return Sensor.fromJson(jsonResponse);
    } else {
      print('updateSensor: HTTP ${response.statusCode} body=${response.body}');
      throw Exception('Failed to update sensor');
    }
  }

  Future<void> deleteSensor(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));

    if (response.statusCode != HttpStatus.ok && response.statusCode != HttpStatus.noContent) {
      print('deleteSensor: HTTP ${response.statusCode} body=${response.body}');
      throw Exception('Failed to delete sensor');
    }
  }

  Future<Sensor> getSensorByOwnerId(int ownerId) async {
    final http.Response response = await http.get(Uri.parse('$baseUrl/owner/$ownerId'));

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = json.decode(response.body);
      return Sensor.fromJson(jsonResponse);
    } else {
      print('getSensorByOwnerId: HTTP ${response.statusCode} body=${response.body}');
      throw Exception('Failed to load sensor by owner');
    }
  }

  Future<List<Sensor>> getSensorsByDeliveryId(int deliveryId) async {
    final http.Response response = await http.get(Uri.parse('$baseUrl/delivery/$deliveryId'));

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Sensor.fromJson(data)).toList();
    } else {
      print('getSensorsByDeliveryId: HTTP ${response.statusCode} body=${response.body}');
      throw Exception('Failed to load sensors by delivery');
    }
  }
}

