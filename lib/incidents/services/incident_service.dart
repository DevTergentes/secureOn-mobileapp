import 'dart:convert';
import 'dart:io';
import 'package:fastflow_app/incidents/models/incident.dart';
import 'package:http/http.dart' as http;

class IncidentsService {
  final String baseUrl = "https://secureon-backend-production.up.railway.app/api/secureon/v1/incidents";

  Future<List<Incident>> getAllIncidents() async {
    final http.Response response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Incident.fromJson(data)).toList();
    } else {
      print('getAllIncidents: HTTP ${response.statusCode} body=${response.body}');
      throw Exception('Failed to load incidents');
    }
  }

  Future<void> addIncident(Incident incident) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode(incident.toJson()),
    );

    if (response.statusCode != HttpStatus.ok && response.statusCode != HttpStatus.created) {
      print('Failed to add incident. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to add incident');
    }
  }

  Future<Incident> getIncidentById(int id) async {
    final http.Response response = await http.get(Uri.parse('$baseUrl/$id'));

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = json.decode(response.body);
      return Incident.fromJson(jsonResponse);
    } else {
      print('Failed to get incident by id. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to load incident');
    }
  }

  Future<List<Incident>> getIncidentsByDelivery(int deliveryId) async {
    final http.Response response =
        await http.get(Uri.parse('$baseUrl/delivery/$deliveryId'));

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Incident.fromJson(data)).toList();
    } else {
      print('getIncidentsByDelivery: HTTP ${response.statusCode} for id=$deliveryId body=${response.body}');
      throw Exception('Failed to load incidents');
    }
  }

  Future<void> deleteIncident(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != HttpStatus.ok && response.statusCode != 204) {
      print('Failed to delete incident. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Error deleting incident');
    }
  }
}
