import 'dart:async';
import 'package:fastflow_app/iam/screens/signup_screen.dart';
import 'package:fastflow_app/management/models/employee.dart';
import 'package:fastflow_app/management/models/delivery.dart';
import 'package:fastflow_app/management/services/employee_service.dart';
import 'package:fastflow_app/management/services/delivery_services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main_screen.dart';

class EmployeesListScreen extends StatefulWidget {
  const EmployeesListScreen({super.key});

  @override
  _EmployeesListScreenState createState() => _EmployeesListScreenState();
}

class _EmployeesListScreenState extends State<EmployeesListScreen> {
  final EmployeeService _employeeService = EmployeeService();
  final DeliveriesService _deliveriesService = DeliveriesService();
  List<Employee> _employees = [];
  List<Employee> _searchResults = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
    _searchController.addListener(_onSearchChanged);
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployees() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final role = prefs.getString('role');

      List<Employee> employees;
      
      // Si es COMPANY, mostrar SOLO empleados con deliveries IN_PROGRESS activos
      if (role == 'COMPANY' && userId != null) {
        // Obtener todos los deliveries
        final allDeliveries = await _deliveriesService.getAllDeliveries();
        
        // Filtrar deliveries IN_PROGRESS de esta compañía (ownerId = userId de COMPANY)
        // y que tengan un employeeId asignado
        final activeDeliveries = allDeliveries.where((d) => 
          d.state == 'IN_PROGRESS' && 
          d.ownerId == userId && 
          d.employeeId != null &&
          d.employeeId != 0
        ).toList();
        
        // Si no hay deliveries activos, lista vacía
        if (activeDeliveries.isEmpty) {
          employees = [];
        } else {
          // Obtener todos los empleados para buscar información
          final allEmployees = await _employeeService.getAllEmployees();
          
          // Obtener employeeIds únicos de los deliveries activos
          final activeEmployeeIds = activeDeliveries
              .map((d) => d.employeeId)
              .where((id) => id != null && id != 0)
              .toSet();
          
          // Filtrar SOLO empleados que tienen deliveries activos
          employees = allEmployees.where((emp) => 
            emp.id != null && activeEmployeeIds.contains(emp.id)
          ).toList();
        }
        
        // NO mostrar empleados permanentes, SOLO los que tienen deliveries activos
        // Los empleados desaparecen automáticamente cuando completan sus deliveries
      } else {
        // Si es otro rol o no hay userId, mostrar todos
        employees = await _employeeService.getAllEmployees();
      }

      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading employees: $e')),
      );
    }
  }

  void _onSearchChanged() {
    String searchQuery = _searchController.text.toLowerCase();
    setState(() {
      if (searchQuery.isEmpty) {
        _searchResults.clear();
      } else {
        _searchResults = _employees.where((employee) {
          return employee.fullName.toLowerCase().contains(searchQuery) ||
                 employee.userId.toString().contains(searchQuery) ||
                 (employee.id != null && employee.id.toString().contains(searchQuery));
        }).toList();
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0)),
              );
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => SignupScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      // Ocultar el botón "+" porque los empleados se crean automáticamente
      // cuando un transportista acepta un delivery
      floatingActionButton: null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _fetchEmployees();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Employees',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.lightGreen,
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Find an employee',
                              style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      filled: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                      hintText: 'Search by name or ID...',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.search, color: Colors.white),
                                  onPressed: _onSearchChanged,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Active Employees',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue, width: 1),
                            ),
                            child: Text(
                              '${_employees.length} active',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_employees.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.grey),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'No active employees. Employees will appear here when they accept a delivery.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    _searchController.text.isNotEmpty
                        ? _buildSearchResults()
                        : _buildEmployeesList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No employees found.'),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildEmployeeTile(_searchResults[index]);
      },
    );
  }

  Widget _buildEmployeesList() {
    if (_employees.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No employees available.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _employees.length,
      itemBuilder: (context, index) {
        return _buildEmployeeTile(_employees[index]);
      },
    );
  }

  Widget _buildEmployeeTile(Employee employee) {
    return FutureBuilder<List<Deliveries>>(
      future: employee.id != null 
          ? _deliveriesService.getDeliveryByEmployeeId(employee.id!)
          : Future.value([]),
      builder: (context, snapshot) {
        final activeDeliveries = snapshot.data?.where((d) => d.state == 'IN_PROGRESS').toList() ?? [];
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            leading: CircleAvatar(
              backgroundColor: Colors.lightGreen,
              radius: 24,
              child: Text(
                employee.fullName.isNotEmpty ? employee.fullName[0].toUpperCase() : 'E',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              employee.fullName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, size: 12, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            '${activeDeliveries.length} Active Delivery${activeDeliveries.length != 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Employee ID: ${employee.id ?? 'N/A'}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  'User ID: ${employee.userId}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                if (activeDeliveries.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...activeDeliveries.where((d) => d.id != null).map((delivery) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ElevatedButton.icon(
                      onPressed: () => _completeDelivery(delivery.id!),
                      icon: const Icon(Icons.done, size: 18),
                      label: Text('Complete Delivery #${delivery.id}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _completeDelivery(int deliveryId) async {
    try {
      await _deliveriesService.completeDelivery(deliveryId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery completed successfully')),
      );
      _fetchEmployees(); // Refrescar la lista
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing delivery: $e')),
      );
    }
  }

}

