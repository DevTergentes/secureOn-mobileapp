import 'package:fastflow_app/incidents/models/incident.dart';
import 'package:fastflow_app/incidents/services/incident_service.dart';
import 'package:flutter/material.dart';

class AddIncidentScreen extends StatefulWidget {
  final int deliveryId;
  const AddIncidentScreen({required this.deliveryId, super.key});

  @override
  _AddIncidentScreenState createState() => _AddIncidentScreenState();
}

class _AddIncidentScreenState extends State<AddIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final IncidentsService _incidentsService = IncidentsService();

  String incidentPlace = '';
  String description = '';

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _saveIncident() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Incident newIncident = Incident(
        incidentPlace: incidentPlace,
        description: description,
        deliveryId: widget.deliveryId,
        date: DateTime.now(),
      );

      try {
        await _incidentsService.addIncident(newIncident);
        Navigator.pop(context, true); // Regresa y actualiza la lista
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add incident')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Incident'),
        backgroundColor: Colors.lightGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildStyledTextField(
                label: 'Incident Place',
                onSaved: (value) => incidentPlace = value!,
                validator: (value) => value!.isEmpty ? 'Please enter the place of incident' : null,
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                label: 'Description',
                onSaved: (value) => description = value!,
                validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveIncident,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  backgroundColor: Colors.orange,
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
