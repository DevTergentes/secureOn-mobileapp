import 'package:fastflow_app/management/services/delivery_services.dart';
import 'package:fastflow_app/management/services/sensor_service.dart';
import 'package:fastflow_app/management/models/sensor.dart';
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
  final SensorService _sensorService = SensorService();

  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _exitPointController = TextEditingController();
  final TextEditingController _routeController = TextEditingController();
  final TextEditingController _stopController = TextEditingController();
  final TextEditingController _combustibleController = TextEditingController();
  final TextEditingController _sensorIdController = TextEditingController();

  List<Sensor> _availableSensors = [];
  Sensor? _selectedSensor;
  bool _isLoadingSensors = true;

  @override
  void initState() {
    super.initState();
    _loadSensors();
  }

  Future<void> _loadSensors() async {
    try {
      final sensors = await _sensorService.getAllSensors();
      setState(() {
        _availableSensors = sensors;
        _isLoadingSensors = false;
      });
    } catch (e) {
      print('Error loading sensors: $e');
      setState(() {
        _isLoadingSensors = false;
      });
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _descriptionController.dispose();
    _exitPointController.dispose();
    _routeController.dispose();
    _stopController.dispose();
    _combustibleController.dispose();
    _sensorIdController.dispose();
    super.dispose();
  }

  Future<void> _saveDelivery() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final ownerId = prefs.getInt('userId');

    // Obtener el sensor ID del dropdown o del campo manual
    final int? sensorId = _selectedSensor?.id ?? int.tryParse(_sensorIdController.text);

    final newDelivery = Deliveries(
      destination: _destinationController.text,
      packageDescription: _descriptionController.text,
      exitPoint: _exitPointController.text,
      route: _routeController.text,
      stop: _stopController.text,
      combustibleType: _combustibleController.text,
      state: 'PENDING',
      employeeId: null, // aún no asignado
      ownerId: ownerId!,
      sensorId: sensorId, // Asociar el sensor al delivery
    );
    try {
      final createdDelivery = await _deliveriesService.addDelivery(newDelivery);
      
      // Mostrar diálogo con la información para Wokwi
      _showWokwiConfigDialog(createdDelivery.id!, createdDelivery.sensorId ?? sensorId ?? 1);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating delivery: $e')),
      );
    }
  }

  void _showWokwiConfigDialog(int deliveryId, int sensorId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Delivery Created!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configure these values in your Wokwi sensor:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_shipping, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'DELIVERY_ID = $deliveryId',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.sensors, size: 20, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'SENSOR_ID = $sensorId',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Update these #define values in your Wokwi sketch.ino file, then start the simulation.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              Navigator.of(context).pop(true); // Volver a la lista
            },
            child: const Text('OK', style: TextStyle(color: Colors.lightGreen)),
          ),
        ],
      ),
    );
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
                const SizedBox(height: 16),
                // Selector de Sensor
                Container(
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
                  child: _isLoadingSensors
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _availableSensors.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(8),
                              child: TextFormField(
                                controller: _sensorIdController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Sensor ID (manual)',
                                  hintText: 'Enter sensor ID for Wokwi',
                                  labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: const Icon(Icons.sensors, color: Colors.orange),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                ),
                              ),
                            )
                          : DropdownButtonFormField<Sensor>(
                              value: _selectedSensor,
                              decoration: InputDecoration(
                                labelText: 'Select Sensor',
                                labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.sensors, color: Colors.orange),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              ),
                              items: _availableSensors.map((sensor) {
                                return DropdownMenuItem<Sensor>(
                                  value: sensor,
                                  child: Text('Sensor #${sensor.id} (Owner: ${sensor.ownerId})'),
                                );
                              }).toList(),
                              onChanged: (Sensor? newValue) {
                                setState(() {
                                  _selectedSensor = newValue;
                                });
                              },
                            ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '💡 The Sensor ID will be shown after creating the delivery. Use it in your Wokwi sketch.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),
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
