import 'package:fastflow_app/iam/screens/login_screen.dart';
import 'package:flutter/material.dart';

import '../services/iam_service.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final AuthService _authService = AuthService();

  String _selectedRole = 'EMPLOYEE';
  final List<String> _roles = ['EMPLOYEE', 'COMPANY'];

  bool _obscurePassword = true;

  void _register() async {
    final response = await _authService.signUp(
      _usernameController.text,
      _fullNameController.text,
      _emailController.text,
      _selectedRole,
      _passwordController.text,
    );
    if (response.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      // Registro exitoso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registro exitoso')),
      );
    } else {
      // Error en el registro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.body}')),
      );
    }
  }

  @override  
  Widget build(BuildContext context) {  
    return Scaffold(  
      appBar: AppBar(title: const Text('Register')),  
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24.0,
          right: 24.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
          top: 24.0,),
        child: Center(
          child: Card(  
            elevation: 8.0,  
            child: Padding(  
              padding: const EdgeInsets.all(16.0),  
              child: Column(  
                mainAxisAlignment: MainAxisAlignment.center,  
                crossAxisAlignment: CrossAxisAlignment.stretch,  
                children: [  
                  _buildTextField(  
                    controller: _usernameController,  
                    labelText: 'Username',  
                    prefixIcon: Icons.person,  
                  ),  
                  const SizedBox(height: 16.0),
                  _buildTextField(
                    controller: _fullNameController,
                    labelText: 'Full Name',
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16.0),
                  _buildTextField(  
                    controller: _emailController,  
                    labelText: 'Email',  
                    prefixIcon: Icons.email,  
                  ),  
                  const SizedBox(height: 16.0),  
                  _buildTextField(  
                    controller: _passwordController,  
                    labelText: 'Password',  
                    prefixIcon: Icons.lock,  
                    obscureText: true,
                    isPassword: true,
                  ),
                  const SizedBox(height: 16.0),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    items: _roles.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role == 'EMPLOYEE' ? 'Employee' : 'Company'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Select a rol',
                      prefixIcon: const Icon(Icons.assignment_ind),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(
                          color: Colors.lightGreen,
                          width: 2.0,
                        ),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                    ),
                  ),
                  const SizedBox(height: 24.0),  
                  ElevatedButton(  
                    onPressed: () {  
                      _register();
                    }, 
                    style: ButtonStyle(  
                      backgroundColor: MaterialStateProperty.all(Colors.lightGreen),
                      foregroundColor: MaterialStateProperty.all(Colors.white),  
                      elevation: MaterialStateProperty.all(4.0),  
                      shape: MaterialStateProperty.all(  
                        RoundedRectangleBorder(  
                          borderRadius: BorderRadius.circular(10.0),  
                        ),  
                      ),  
                    ), 
                    child: const Text('Register'),  
                  ),  
                ],  
              ),  
            ),  
          ),  
        ),  
      ),  
    );  
  }  
  
  Widget _buildTextField({  
    required TextEditingController controller,  
    required String labelText,  
    IconData? prefixIcon,  
    bool obscureText = false,
    bool isPassword = false,
  }) {  
    return TextField(  
      controller: controller,  
      obscureText: isPassword ? _obscurePassword : obscureText,
      decoration: InputDecoration(  
        labelText: labelText,  
        prefixIcon: prefixIcon!= null? Icon(prefixIcon) : null,
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        )
            : null,
        border: OutlineInputBorder(  
          borderRadius: BorderRadius.circular(10.0),  
        ),  
        focusedBorder: OutlineInputBorder(  
          borderRadius: BorderRadius.circular(10.0),  
          borderSide: const BorderSide(  
            color: Colors.lightGreen,
            width: 2.0,  
          ),  
        ),  
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),  
      ),  
    );  
  }  
}  