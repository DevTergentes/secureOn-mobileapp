import 'package:flutter/material.dart';
import 'package:fastflow_app/management/models/servicios.dart';
import 'package:fastflow_app/management/services/servicios_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main_screen.dart';

/**
 * muestra el formulario para añadir un servicio (company)
 */
class ServiciosAddScreen extends StatefulWidget {
  final int deliveryId;

  const ServiciosAddScreen({required this.deliveryId,super.key});

  @override
  _ServiciosAddScreenState createState() => _ServiciosAddScreenState();
}

class _ServiciosAddScreenState extends State<ServiciosAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final ServiciosService _serviciosService = ServiciosService();

  String nameService = '';
  String description = '';

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _saveService() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final prefs = await SharedPreferences.getInstance();
      final ownerId = prefs.getInt('userId');

      final newService = Servicios(
        nameService: nameService,
        description: description,
        ownerId: ownerId!,
        deliveryId: widget.deliveryId,
      );

      try {
        await _serviciosService.addService(newService);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)),
              (route) => false,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add service')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Service'),
        backgroundColor: Colors.lightGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildStyledTextField(
                label: 'Service Name',
                onSaved: (value) => nameService = value!,
                validator: (value) => value!.isEmpty ? 'Please enter a service name' : null,
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                label: 'Description',
                onSaved: (value) => description = value!,
                validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveService,
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
                  'Save',
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
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
    TextEditingController? controller,
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
        onSaved: onSaved,
        validator: validator,
      ),
    );
  }
}
