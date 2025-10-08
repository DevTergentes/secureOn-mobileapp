import 'package:fastflow_app/management/screens/servicios_add_screen.dart';
import 'package:fastflow_app/management/services/employee_service.dart';
import 'package:fastflow_app/management/services/servicios_service.dart';
import 'package:flutter/material.dart';
import 'package:fastflow_app/management/models/delivery.dart';
import 'package:fastflow_app/management/services/delivery_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'monitoring_screen.dart';

/**
 * muestra los detalles de cada entrega y permite cambiar el estado de la entrega a in progress (employee)
 * o añadir un servicio (company)
 */
class DeliveryDetailScreen extends StatefulWidget {
  final int deliveryId;

  const DeliveryDetailScreen({required this.deliveryId, super.key});

  @override
  _DeliveryDetailScreenState createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  final DeliveriesService _deliveriesService = DeliveriesService();
  final EmployeeService _employeeService = EmployeeService();
  final ServiciosService _servicesService = ServiciosService();
  Deliveries? _delivery;
  bool _isLoading = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _fetchDeliveryDetails();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role');
    });
  }

  Future<void> _fetchDeliveryDetails() async {
    try {
      Deliveries delivery = await _deliveriesService.getDeliveryById(widget.deliveryId);
      setState(() {
        _delivery = delivery;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptDelivery() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception('User not logged in');
      }
      final employeeId = await _employeeService.getEmployeeIdByUserId(userId);
      await _deliveriesService.acceptDelivery(widget.deliveryId, employeeId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery started successfully')),
      );

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DeliveryInProgressScreenScreen(
              deliveryId: widget.deliveryId,
            ),
          ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _delivery == null
              ? const Center(child: Text('No details available'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      Text(
                        _delivery!.destination,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _delivery!.packageDescription,
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      const Divider(height: 32, color: Colors.lightGreen),
                      const Text(
                        'Route Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Exit Point: ${_delivery!.exitPoint}'),
                      Text('Route: ${_delivery!.route}'),
                      Text('Stop: ${_delivery!.stop}'),
                      const Divider(height: 32, color: Colors.lightGreen),
                      const Text(
                        'Combustible Type',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_delivery!.combustibleType),

                      const SizedBox(height: 24),

                      if (_userRole == 'COMPANY')
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ServiciosAddScreen(deliveryId: widget.deliveryId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create Service'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                      if (_userRole == 'EMPLOYEE')
                      ElevatedButton(
                        onPressed: () {
                          // Lógica para iniciar la entrega
                          _acceptDelivery();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: const Text('START', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
    );
  }
}
