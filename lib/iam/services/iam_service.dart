import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = 'https://chemtrack-backend-production.up.railway.app/api/v1/auth';

  Future<http.Response> signIn(String username, String password) async {
    final url = Uri.parse('$baseUrl/signin');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );
    return response;
  }

  Future<http.Response> signUp(String username, String fullName, String email, String role, String password) async {
    final url = Uri.parse('$baseUrl/signup');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'fullName': fullName, 'email': email, 'password': password, 'role': role}),
    );
    return response;
  }

}