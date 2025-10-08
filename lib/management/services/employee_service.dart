import 'dart:convert';
import 'package:http/http.dart' as http;

class EmployeeService {
  final String baseUrl = "https://chemtrack-backend-production.up.railway.app/api/safeflow/v1/employees";

  Future<int> getEmployeeIdByUserId(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/$userId'),
    );
    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonList = json.decode(response.body);
      if (jsonList is List && jsonList.isNotEmpty) {
        return jsonList[0]['id'];
      } else {
        throw Exception('Employee list is empty or invalid');
      }
    } else {
      throw Exception('Failed to fetch employee ID - Status: ${response.statusCode}');
    }
  }
}