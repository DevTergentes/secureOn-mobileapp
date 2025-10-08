import 'dart:convert';
import 'dart:io';

import 'package:fastflow_app/management/models/delivery.dart';
import 'package:http/http.dart' as http;

class DeliveriesService {
  final String baseUrl = "http://localhost:8080/api/safe-flow/v1/deliveries";

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
    final http.Response response =
        await http.get(Uri.parse('$baseUrl/state/PENDING'));

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Deliveries.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load deliveries');
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

    if (response.statusCode == HttpStatus.noContent ||
        response.statusCode == HttpStatus.ok) {
      print(
          'Delivery $deliveryId status updated to IN-PROGRESS successfully for employee $employeeId.');
      // No es necesario hacer nada más si la operación fue exitosa y no hay contenido.
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

    if (response.statusCode == HttpStatus.noContent ||
        response.statusCode == HttpStatus.ok) {
      print('Delivery $deliveryId status updated to COMPLETED successfully');
      // No es necesario hacer nada más si la operación fue exitosa y no hay contenido.
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

    if (response.statusCode != HttpStatus.noContent) {
      throw Exception('Failed to delete delivery');
    }
  }

  Future<String> getDeliveryState(int deliveryId) async {
    final response = await http.get(Uri.parse('$baseUrl/$deliveryId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['state']; // devuelve el estado como string
    } else {
      throw Exception('Failed to load delivery state');
    }
  }

  Future<void> addDelivery(Deliveries delivery) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode(delivery.toJson()),
    );

    if (response.statusCode != HttpStatus.created) {
      throw Exception('Failed to add delivery');
    }
  }
}
