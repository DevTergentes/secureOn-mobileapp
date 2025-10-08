import 'package:fastflow_app/management/services/delivery_services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/delivery.dart';

/**
 * formulario para añadir una nueva entrega
 */
class DeliveryAddScreen extends StatefulWidget {
  const DeliveryAddScreen({super.key});

  @override
  _DeliveryAddScreenState createState() => _DeliveryAddScreenState();
}

class _DeliveryAddScreenState extends State<DeliveryAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final DeliveriesService _deliveriesService = DeliveriesService();

  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _exitPointController = TextEditingController();
  final TextEditingController _routeController = TextEditingController();
  final TextEditingController _stopController = TextEditingController();
  final TextEditingController _combustibleController = TextEditingController();

  @override
  void dispose() {
    _destinationController.dispose();
    _descriptionController.dispose();
    _exitPointController.dispose();
    _routeController.dispose();
    _stopController.dispose();
    _combustibleController.dispose();
    super.dispose();
  }

  Future<void> _saveDelivery() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final ownerId = prefs.getInt('userId');

    final newDelivery = Deliveries(
      destination: _destinationController.text,
      packageDescription: _descriptionController.text,
      exitPoint: _exitPointController.text,
      route: _routeController.text,
      stop: _stopController.text,
      combustibleType: _combustibleController.text,
      state: 'PENDING',
      employeeId: 0,
      // aún no asignado
      ownerId: ownerId!,
    );
    try {
      await _deliveriesService.addDelivery(newDelivery);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery created successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating delivery: $e')),
      );
    }
  }



    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Add Delivery'),
          backgroundColor: Colors.lightGreen,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildStyledTextField(
                  label: 'Destination',
                  controller: _destinationController,
                ),
                const SizedBox(height: 16),
                _buildStyledTextField(
                  label: 'Package Description',
                  controller: _descriptionController,
                ),
                const SizedBox(height: 16),
                _buildStyledTextField(
                  label: 'Exit Point',
                  controller: _exitPointController,
                ),
                const SizedBox(height: 16),
                _buildStyledTextField(
                  label: 'Route',
                  controller: _routeController,
                ),
                const SizedBox(height: 16),
                _buildStyledTextField(
                  label: 'Stop',
                  controller: _stopController,
                ),
                const SizedBox(height: 16),
                _buildStyledTextField(
                  label: 'Combustible Type',
                  controller: _combustibleController,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveDelivery,
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
                    'Save Delivery',
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
    required TextEditingController controller,
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
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }
}
