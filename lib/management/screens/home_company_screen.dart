import 'dart:async';
import 'package:fastflow_app/iam/screens/signup_screen.dart';
import 'package:fastflow_app/management/models/delivery.dart';
import 'package:fastflow_app/management/services/delivery_services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../incidents/screens/incident_list_screen.dart';
import '../../main_screen.dart';
import 'monitoring_screen.dart';
import 'sensors_list_screen.dart';
import 'employees_list_screen.dart';

/**
 * muestra los tres entregas más recientes y permite buscar por destino
 **/
class HomeCompanyScreen extends StatefulWidget {
  const HomeCompanyScreen({super.key});

  @override
  _HomeCompanyScreenState createState() => _HomeCompanyScreenState();
}

class _HomeCompanyScreenState extends State<HomeCompanyScreen> {
  final DeliveriesService _deliveriesService = DeliveriesService();
  List<Deliveries> _deliveries = [];
  List<Deliveries> _searchResults = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchAllDeliveries();
    _loadUserRole();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllDeliveries() async {
    try {
      List<Deliveries> deliveries = await _deliveriesService.getAllDeliveries();
      setState(() {
        _deliveries = deliveries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    setState(() {
      _userRole = role;
    });
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
    await prefs.clear();
    // Redirige al login
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => SignupScreen()),
          (route) => false,
    );
  }

  List<Deliveries> _filteredDeliveries() {
    return _deliveries.where((delivery) {
      return delivery.state == 'COMPLETED' || delivery.state == 'IN_PROGRESS';
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    final recentDeliveries = _filteredDeliveries().take(3).toList();
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
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Welcome',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.left,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _userRole != null ? 'Role: $_userRole' : 'Loading role...',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                      'Find your delivery',
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
                              hintText: 'Search deliveries...',
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
            // Management Cards Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Text(
                'Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildManagementCard(
                      icon: Icons.sensors,
                      title: 'Sensors',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SensorsListScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildManagementCard(
                      icon: Icons.people,
                      title: 'Employees',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EmployeesListScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Last deliveries',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                  if (_filteredDeliveries().length > 3)
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 3)),
                        );
                      },
                      child: const Text(
                        'View more',
                        style: TextStyle(color: Colors.lightGreen),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _searchController.text.isNotEmpty
                  ? _buildSearchResults()
                  : Column(
                children: recentDeliveries
                    .map((delivery) => _buildDeliveryCard(delivery))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
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
              trailing: Text("EmployeeId: ${delivery.employeeId}"),
            ),
            if (delivery.state == 'IN_PROGRESS') // solo mostrar botones si está activo
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeliveryInProgressScreenScreen(deliveryId: delivery.id!),
                        ),
                      );
                    },
                    icon: const Icon(Icons.monitor_heart, color: Colors.lightGreen),
                    label: const Text("Monitoring", style: TextStyle(color: Colors.lightGreen)),
                  ),
                  const SizedBox(width: 8),
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

  Widget _buildManagementCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
