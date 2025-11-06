import 'dart:convert';
import 'dart:io';
import 'package:fastflow_app/management/models/employee.dart';
import 'package:http/http.dart' as http;

class EmployeeService {
  final String baseUrl = "https://secureon-backend-production.up.railway.app/api/secureon/v1/employees";

  Future<List<Employee>> getAllEmployees() async {
    final http.Response response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Employee.fromJson(data)).toList();
    } else {
      print('getAllEmployees: HTTP ${response.statusCode} body=${response.body}');
      throw Exception('Failed to load employees');
    }
  }

  Future<Employee> addEmployee(Employee employee) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode(employee.toJson()),
    );

    if (response.statusCode == HttpStatus.ok || response.statusCode == HttpStatus.created) {
      final jsonResponse = json.decode(response.body);
      return Employee.fromJson(jsonResponse);
    } else {
      print('addEmployee: HTTP ${response.statusCode} body=${response.body}');
      throw Exception('Failed to add employee');
    }
  }

  Future<List<Employee>> getEmployeesByUserId(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/$userId'),
    );
    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == HttpStatus.ok) {
      final jsonList = json.decode(response.body);
      if (jsonList is List) {
        return jsonList.map((data) => Employee.fromJson(data)).toList();
      } else {
        throw Exception('Employee list is invalid format');
      }
    } else {
      throw Exception(
          'Failed to fetch employees - Status: ${response.statusCode}');
    }
  }

  Future<int> getEmployeeIdByUserId(int userId) async {
    final employees = await getEmployeesByUserId(userId);
    if (employees.isNotEmpty) {
      return employees[0].id ?? 0;
    } else {
      throw Exception('Employee list is empty');
    }
  }

  Future<List<Employee>> getEmployeesByCompanyId(int companyId) async {
    final response = await http.get(Uri.parse(baseUrl));
    
    if (response.statusCode == HttpStatus.ok) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      final allEmployees = jsonResponse.map((data) => Employee.fromJson(data)).toList();
      // Filtrar empleados por companyId
      return allEmployees.where((emp) => emp.companyId == companyId).toList();
    } else {
      print('getEmployeesByCompanyId: HTTP ${response.statusCode} body=${response.body}');
      throw Exception('Failed to load employees by company');
    }
  }

  Future<void> deleteEmployee(int employeeId) async {
    final response = await http.delete(Uri.parse('$baseUrl/$employeeId'));

    if (response.statusCode != HttpStatus.ok && response.statusCode != HttpStatus.noContent) {
      print('deleteEmployee: HTTP ${response.statusCode} body=${response.body}');
      throw Exception('Failed to delete employee');
    }
  }
}
