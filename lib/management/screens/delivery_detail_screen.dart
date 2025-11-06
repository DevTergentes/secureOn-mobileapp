import 'package:fastflow_app/management/screens/servicios_add_screen.dart';
import 'package:fastflow_app/management/services/employee_service.dart';
import 'package:fastflow_app/management/services/record_service.dart';
import 'package:fastflow_app/management/models/employee.dart';
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
  final RecordService _recordService = RecordService();
  Deliveries? _delivery;
  List<int> _activeSensorIds = []; // IDs de sensores que están enviando records para este delivery
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
      
      // Obtener sensores activos desde los records
      List<int> sensorIds = [];
      if (delivery.state == 'IN_PROGRESS') {
        try {
          final records = await _recordService.getAllRecords(widget.deliveryId);
          // Extraer IDs únicos de sensores que están enviando records
          sensorIds = records.map((r) => r.sensorId).toSet().toList();
        } catch (e) {
          print('Error loading sensor records: $e');
        }
      }
      
      setState(() {
        _delivery = delivery;
        _activeSensorIds = sensorIds;
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

      // Intentar obtener employeeId, si no existe, crear el empleado automáticamente
      int employeeId;
      try {
        employeeId = await _employeeService.getEmployeeIdByUserId(userId);
      } catch (e) {
        // Si el empleado no existe, crearlo automáticamente
        // Esto permite que cualquier transportista pueda aceptar deliveries
        print('Employee not found for userId $userId, creating automatically...');
        
        final employee = Employee(
          userId: userId,
          fullName: 'Transportista $userId', // Nombre temporal, puede actualizarse después
          // companyId se asignará automáticamente cuando acepte el delivery
        );
        
        try {
          final createdEmployee = await _employeeService.addEmployee(employee);
          employeeId = createdEmployee.id ?? 0;
          if (employeeId == 0) {
            throw Exception('Failed to create employee');
          }
          print('Employee created automatically with ID: $employeeId');
        } catch (createError) {
          throw Exception('Failed to create employee automatically: $createError');
        }
      }

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

                      const Divider(height: 32, color: Colors.lightGreen),
                      const Text(
                        'Delivery Status',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getStateColor(_delivery!.state).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getStateColor(_delivery!.state),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getStateIcon(_delivery!.state),
                              color: _getStateColor(_delivery!.state),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Status: ${_delivery!.state}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getStateColor(_delivery!.state),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_delivery!.employeeId != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Assigned Employee ID: ${_delivery!.employeeId}',
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                      // Mostrar sensores activos si el delivery está IN_PROGRESS
                      if (_delivery!.state == 'IN_PROGRESS' && _activeSensorIds.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(height: 32, color: Colors.lightGreen),
                        const Text(
                          'Active Sensors',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ..._activeSensorIds.map((sensorId) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.sensors, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'Sensor #$sensorId',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],

                      const SizedBox(height: 24),

                      if (_userRole == 'COMPANY')
                      Column(
                        children: [
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
                          if (_delivery!.state == 'PENDING')
                          const SizedBox(height: 8),
                          if (_delivery!.state == 'PENDING')
                          Text(
                            'Waiting for an employee to accept this delivery',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
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

  Color _getStateColor(String state) {
    switch (state.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'IN_PROGRESS':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStateIcon(String state) {
    switch (state.toUpperCase()) {
      case 'PENDING':
        return Icons.pending;
      case 'IN_PROGRESS':
        return Icons.directions_run;
      case 'COMPLETED':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }
}
