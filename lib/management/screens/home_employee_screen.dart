import 'dart:async';
import 'package:fastflow_app/iam/screens/signup_screen.dart';
import 'package:fastflow_app/management/models/delivery.dart';
import 'package:fastflow_app/management/services/delivery_services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../incidents/screens/incident_list_screen.dart';
import '../../main_screen.dart';
import '../services/employee_service.dart';
import 'monitoring_screen.dart';

/**
 * muestra las tres entregas por employeeId más recientes y permite buscar por destino
 */
class HomeEmployeeScreen extends StatefulWidget {
  const HomeEmployeeScreen({super.key});

  @override
  _HomeEmployeeScreenState createState() => _HomeEmployeeScreenState();
}

class _HomeEmployeeScreenState extends State<HomeEmployeeScreen> {
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
    _fetchDeliveriesByEmployeeId();
    _loadUserRole();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDeliveriesByEmployeeId() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      if (userId == null) throw Exception('User not logged in');

      final employeeId = await _employeeService.getEmployeeIdByUserId(userId);
      final List<Deliveries> deliveries = await _deliveriesService.getDeliveryByEmployeeId(employeeId);
      setState(() {
        _deliveries = deliveries;
        _searchResults = deliveries;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    print('Loaded role: $role');
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
                                MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)),
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
}
