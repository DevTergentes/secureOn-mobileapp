import 'dart:convert';
import 'dart:io';
import 'package:fastflow_app/incidents/models/incident.dart';
import 'package:http/http.dart' as http;


class IncidentsService {
  final String baseUrl = "https://chemtrack-backend-production.up.railway.app/api/safe-flow/v1/incidents";

  Future<List<Incident>> getAllIncidents() async {
    final http.Response response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Incident.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load incidents');
    }
  }

  Future<void> addIncident(Incident incident) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode(incident.toJson()),
    );

    if (response.statusCode != HttpStatus.created) {
      throw Exception('Failed to add incident');
    }
  }

  Future<List<Incident>> getIncidentsByDelivery(int deliveryId) async {
    final http.Response response = await http.get(Uri.parse('$baseUrl/delivery/$deliveryId'));

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Incident.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load incidents');
    }
  }

  Future<void> deleteIncident(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 204) {
      throw Exception('Error deleting incident');
    }
  }
}
