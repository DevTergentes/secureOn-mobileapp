import 'dart:async';
import 'package:fastflow_app/iam/screens/signup_screen.dart';
import 'package:fastflow_app/management/models/delivery.dart';
import 'package:fastflow_app/management/services/delivery_services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../incidents/screens/incident_list_screen.dart';
import '../services/employee_service.dart';

/**
 * muestra una lista de las entregas completadas por el employeeId (employee) y todas las entregas completadas (company)
 * para ver los incidentes asociados a cada entrega
 */
class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  _RecordScreenState createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final DeliveriesService _deliveriesService = DeliveriesService();
  final EmployeeService _employeeService = EmployeeService();
  List<Deliveries> _deliveries = [];
  List<Deliveries> _searchResults = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadUserRoleAndDeliveries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRoleAndDeliveries() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final role = prefs.getString('role');

      if (userId == null || role == null) {
        throw Exception('User not logged in');
      }

      _userRole = role;

      List<Deliveries> deliveries;

      if (role == 'COMPANY') {
        deliveries = await _deliveriesService.getAllDeliveries();
      } else {
        final employeeId = await _employeeService.getEmployeeIdByUserId(userId);
        deliveries = await _deliveriesService.getDeliveryByEmployeeId(employeeId);
      }

      setState(() {
        _deliveries = deliveries;
        _searchResults = deliveries;
      });
    } catch (e) {
      print('Error loading deliveries: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading deliveries: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    String searchQuery = _searchController.text.toLowerCase();
    setState(() {
      if (searchQuery.isEmpty) {
        _searchResults = _deliveries;
      } else {
        _searchResults = _deliveries.where((delivery) {
          return delivery.destination.toLowerCase().contains(searchQuery);
        }).toList();
      }
    });
  }

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Elimina todo
    // o solo uno específico:
    // await prefs.remove('userId');

    // Redirige al login
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => SignupScreen()),
          (route) => false,
    );
  }

  List<Deliveries> _filteredDeliveries() {
    return _deliveries.where((delivery) {
      return delivery.state == 'COMPLETED';
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
    onRefresh: _loadUserRoleAndDeliveries,
    child: SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Records',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.left,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search deliveries...',
                  filled: true,
                  fillColor: Colors.grey[200],
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Completed deliveries',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _searchController.text.isNotEmpty
                  ? _buildSearchResults()
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredDeliveries().length,
                itemBuilder: (context, index) {
                  final delivery = _filteredDeliveries()[index];
                  return _buildDeliveryCard(delivery);
                },
              ),
            ),
          ],
        ),
      ),
      )
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildDeliveryCard(_searchResults[index]);
      },
    );
  }

  Widget _buildDeliveryCard(Deliveries delivery) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipOval(
                child: Image.asset(
                  'assets/service_placeholder.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(delivery.destination, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("State: ${delivery.state}"),
            ),
            if (delivery.state == 'COMPLETED') // solo mostrar botones si está activo
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IncidentsListScreen(deliveryId: delivery.id!),
                        ),
                      );
                    },
                    icon: const Icon(Icons.report_problem, color: Colors.orange),
                    label: const Text("Incidents", style: TextStyle(color: Colors.orange)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
