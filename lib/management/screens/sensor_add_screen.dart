import 'package:flutter/material.dart';
import 'package:fastflow_app/management/models/sensor.dart';
import 'package:fastflow_app/management/services/sensor_service.dart';

/**
 * Pantalla para crear o editar un sensor
 */
class SensorAddScreen extends StatefulWidget {
  final Sensor? sensor; // Si es null, se crea nuevo. Si tiene valor, se edita.

  const SensorAddScreen({this.sensor, super.key});

  @override
  _SensorAddScreenState createState() => _SensorAddScreenState();
}

class _SensorAddScreenState extends State<SensorAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final SensorService _sensorService = SensorService();
  final TextEditingController _ownerIdController = TextEditingController();
  bool _safe = true;

  @override
  void initState() {
    super.initState();
    if (widget.sensor != null) {
      // Modo edición
      _ownerIdController.text = widget.sensor!.ownerId.toString();
      _safe = widget.sensor!.safe;
    }
  }

  @override
  void dispose() {
    _ownerIdController.dispose();
    super.dispose();
  }

  Future<void> _saveSensor() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final ownerId = int.tryParse(_ownerIdController.text);
      if (ownerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid Owner ID')),
        );
        return;
      }

      final sensor = Sensor(
        id: widget.sensor?.id,
        ownerId: ownerId,
        safe: _safe,
      );

      try {
        if (widget.sensor == null) {
          // Crear nuevo sensor
          await _sensorService.addSensor(sensor);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sensor created successfully')),
          );
        } else {
          // Actualizar sensor existente
          await _sensorService.updateSensor(widget.sensor!.id!, sensor);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sensor updated successfully')),
          );
        }
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
        title: Text(widget.sensor == null ? 'Add Sensor' : 'Edit Sensor'),
        backgroundColor: Colors.lightGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildStyledTextField(
                label: 'Owner ID',
                controller: _ownerIdController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an Owner ID';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Safety Status',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Safe'),
                            value: true,
                            groupValue: _safe,
                            onChanged: (value) {
                              setState(() {
                                _safe = value!;
                              });
                            },
                            activeColor: Colors.green,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Unsafe'),
                            value: false,
                            groupValue: _safe,
                            onChanged: (value) {
                              setState(() {
                                _safe = value!;
                              });
                            },
                            activeColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveSensor,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  backgroundColor: Colors.lightGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                  shadowColor: Colors.black45,
                ),
                child: Text(
                  widget.sensor == null ? 'Create Sensor' : 'Update Sensor',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

