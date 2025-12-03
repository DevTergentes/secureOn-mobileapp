import 'dart:convert';
import 'dart:io';

import 'package:fastflow_app/management/models/delivery.dart';
import 'package:http/http.dart' as http;

class DeliveriesService {
  final String baseUrl = "https://secureon-backend-production.up.railway.app/api/secureon/v1/deliveries";

  Future<List<Deliveries>> getAllDeliveries() async {
    final http.Response response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Deliveries.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load deliveries');
    }
  }

  Future<List<Deliveries>> getPendingDeliveries() async {
    return getDeliveriesByState('PENDING');
  }

  Future<List<Deliveries>> getDeliveriesByState(String state) async {
    final http.Response response =
        await http.get(Uri.parse('$baseUrl/state/$state'));

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Deliveries.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load deliveries by state: $state');
    }
  }

  Future<List<Deliveries>> getDeliveryByEmployeeId(int employeeId) async {
    final http.Response response =
        await http.get(Uri.parse('$baseUrl/employee/$employeeId'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((data) => Deliveries.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load deliveries');
    }
  }

  Future<void> acceptDelivery(int deliveryId, int employeeId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$deliveryId/in-progress?employeeId=$employeeId'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == HttpStatus.ok) {
      print(
          'Delivery $deliveryId status updated to IN-PROGRESS successfully for employee $employeeId.');
    } else {
      print(
          'Failed to update delivery status. Status code: ${response.statusCode}');
      print('Response body: ${response.body}'); // Útil para depurar
      throw Exception('Failed to update delivery status to in-progress');
    }
  }

  Future<void> completeDelivery(int deliveryId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$deliveryId/completed'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == HttpStatus.ok) {
      print('Delivery $deliveryId status updated to COMPLETED successfully');
    } else {
      print(
          'Failed to update delivery status. Status code: ${response.statusCode}');
      print('Response body: ${response.body}'); // Útil para depurar
      throw Exception('Failed to update delivery status to completed');
    }
  }

  Future<Deliveries> getDeliveryById(int id) async {
    final http.Response response = await http.get(Uri.parse('$baseUrl/$id'));

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = json.decode(response.body);
      return Deliveries.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to load delivery details');
    }
  }

  Future<void> deleteDelivery(int id) async {
    final http.Response response = await http.delete(Uri.parse('$baseUrl/$id'));

    if (response.statusCode != HttpStatus.ok && response.statusCode != HttpStatus.noContent) {
      print('Failed to delete delivery. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to delete delivery');
    }
  }

  Future<String> getDeliveryState(int deliveryId) async {
    final response = await http.get(Uri.parse('$baseUrl/$deliveryId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final state = data['state'];
      if (state is String && state.isNotEmpty) {
        return state;
      }
      print('getDeliveryState: Response JSON does not contain "state" key or is empty: ${response.body}');
      throw Exception('Invalid delivery payload (missing state)');
    } else {
      print('getDeliveryState: HTTP ${response.statusCode} body=${response.body}');
      throw Exception('Failed to load delivery state');
    }
  }

  Future<Deliveries> addDelivery(Deliveries delivery) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode(delivery.toJson()),
    );

    if (response.statusCode == HttpStatus.ok || response.statusCode == HttpStatus.created) {
      final jsonResponse = json.decode(response.body);
      return Deliveries.fromJson(jsonResponse);
    } else {
      print('Failed to add delivery. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to add delivery');
    }
  }
}
