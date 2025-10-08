import 'dart:ffi';

class User {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final String role;
  final String password;

  User({required this.id, required this.username, required this.fullName, required this.email, required this.role, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'email': email,
      'role': role,
      'password': password,
    };
  }
}