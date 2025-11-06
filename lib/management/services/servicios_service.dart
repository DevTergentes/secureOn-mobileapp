import 'dart:convert';
import 'dart:io';
import 'package:fastflow_app/management/models/servicios.dart';
import 'package:http/http.dart' as http;

class ServiciosService {
  final String baseUrl = "https://secureon-backend-production.up.railway.app/api/secureon/v1/services";

  Future<List<Servicios>> getAll() async {
    final http.Response response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == HttpStatus.ok) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse is Map<String, dynamic> &&
          jsonResponse.containsKey("results")) {
        final List<dynamic> maps = jsonResponse["results"];
        return maps.map((map) => Servicios.fromJson(map)).toList();
      } else if (jsonResponse is List<dynamic>) {
        return jsonResponse.map((map) => Servicios.fromJson(map)).toList();
      } else {
        throw Exception('Unexpected JSON structure');
      }
    } else {
      throw Exception('Failed to load services');
    }
  }

  Future<void> addService(Servicios service) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode(service.toJson()),
    );

    if (response.statusCode != HttpStatus.ok && response.statusCode != HttpStatus.created) {
      print('Failed to add service. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to add service');
    }
  }

  Future<void> deleteService(int id) async {
    final http.Response response = await http.delete(Uri.parse('$baseUrl/$id'));

    if (response.statusCode != HttpStatus.ok && response.statusCode != HttpStatus.noContent) {
      print('Failed to delete service. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to delete service');
    }
  }
}
