import 'package:flutter/material.dart';
import 'package:fastflow_app/management/models/employee.dart';
import 'package:fastflow_app/management/services/employee_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/**
 * Pantalla para crear un nuevo empleado
 */
class EmployeeAddScreen extends StatefulWidget {
  const EmployeeAddScreen({super.key});

  @override
  _EmployeeAddScreenState createState() => _EmployeeAddScreenState();
}

class _EmployeeAddScreenState extends State<EmployeeAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final EmployeeService _employeeService = EmployeeService();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();

  @override
  void dispose() {
    _userIdController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _saveEmployee() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final userId = int.tryParse(_userIdController.text);
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid User ID')),
        );
        return;
      }

      // Obtener el userId de la COMPANY actual para asignar como companyId
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getInt('userId');
      final role = prefs.getString('role');

      final employee = Employee(
        userId: userId,
        fullName: _fullNameController.text,
        companyId: role == 'COMPANY' ? companyId : null, // Solo asignar si es COMPANY quien crea
      );

      try {
        await _employeeService.addEmployee(employee);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee created successfully')),
        );
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Employee'),
        backgroundColor: Colors.lightGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildStyledTextField(
                label: 'User ID',
                controller: _userIdController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a User ID';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                label: 'Full Name',
                controller: _fullNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveEmployee,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  backgroundColor: Colors.lightGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                  shadowColor: Colors.black45,
                ),
                child: const Text(
                  'Create Employee',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required String label,
    TextEditingController? controller,
    TextInputType? keyboardType,
    required FormFieldValidator<String> validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        validator: validator,
      ),
    );
  }
}

