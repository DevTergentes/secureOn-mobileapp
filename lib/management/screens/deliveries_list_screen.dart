import 'package:fastflow_app/management/screens/delivery_add_screen.dart';
import 'package:fastflow_app/management/services/employee_service.dart';
import 'package:flutter/material.dart';
import 'package:fastflow_app/management/models/delivery.dart';
import 'package:fastflow_app/management/services/delivery_services.dart';
import 'package:fastflow_app/management/screens/delivery_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../incidents/screens/incident_list_screen.dart';
import 'monitoring_screen.dart';

/**
 * DeliveriesListScreen muestra una lista de entregas PENDIENTES con botones para aceptar o rechazar (employee)
 * o eliminar, añadir, ver detalles de una entrega (company) y entregas en progreso, para ver el monitoreo de la
 * entrega y gestionar incidentes.
 */
class DeliveriesListScreen extends StatefulWidget {
  const DeliveriesListScreen({super.key});

  @override
  _DeliveriesListScreenState createState() => _DeliveriesListScreenState();
}

class _DeliveriesListScreenState extends State<DeliveriesListScreen>  with TickerProviderStateMixin {
  final DeliveriesService _deliveriesService = DeliveriesService();
  final EmployeeService _employeeService = EmployeeService();
  List<Deliveries> _pendingDeliveries = [];
  List<Deliveries> _inProgressDeliveries = [];
  List<Deliveries> _searchResults = [];
  bool _isLoadingPending = true;
  bool _isLoadingInProgress = true;
  int _currentTabIndex = 0;
  String? _userRole;

  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadUserRole();
    _fetchPendingDeliveries();
    _fetchInProgressDeliveries();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    FocusScope.of(context).unfocus(); //Oculta el teclado
    setState(() {
      _currentTabIndex = _tabController.index;
    });
    _searchController.clear();
    if (_currentTabIndex == 0) {
      _fetchPendingDeliveries();
    } else if (_currentTabIndex == 1) {
      _fetchInProgressDeliveries();
    }
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role');
    });
  }

  Future<void> _fetchPendingDeliveries() async {
    setState(() {
      _isLoadingPending = true;
    });
    try {
      List<Deliveries> deliveries = await _deliveriesService.getPendingDeliveries();
      setState(() {
        _pendingDeliveries = deliveries;
      });
    } finally {
      setState(() {
        _isLoadingPending = false;
      });
    }
  }

  Future<void> _fetchInProgressDeliveries() async {
    setState(() {
      _isLoadingInProgress = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final role = prefs.getString('role');

      if (userId == null || role == null) throw Exception('User not logged in');

      List<Deliveries> deliveries;

      if (role == 'COMPANY') {
        deliveries = await _deliveriesService.getAllDeliveries();
      } else {
        final employeeId = await _employeeService.getEmployeeIdByUserId(userId);
        deliveries = await _deliveriesService.getDeliveryByEmployeeId(employeeId);
      }

      setState(() {
        _inProgressDeliveries = deliveries.where((d) => d.state == 'IN_PROGRESS').toList();
      });
    } finally {
      setState(() => _isLoadingInProgress = false);
    }
  }

  void _declineDelivery(int id) {
    setState(() {
      _pendingDeliveries.removeWhere((d) => d.id == id);
      _searchResults.removeWhere((d) => d.id == id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delivery declined')),
    );
  }

  void _confirmDeleteDelivery(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete delivery'),
        content: const Text('Are you sure you want to delete this delivery?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deliveriesService.deleteDelivery(id);
              _fetchPendingDeliveries();
              _fetchInProgressDeliveries();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delivery deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateDelivery() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DeliveryAddScreen()),
    ).then((_) {
      _fetchPendingDeliveries();
      _fetchInProgressDeliveries();
    });
  }

  void _onSearchChanged() {
    String searchQuery = _searchController.text.toLowerCase();
    setState(() {
      _searchResults = _pendingDeliveries.where((delivery) {
        return delivery.destination.toLowerCase().contains(searchQuery) ||
               delivery.packageDescription.toLowerCase().contains(searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Deliveries',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.amber,
            labelColor: Colors.lightGreen,
            indicatorWeight: 4.0,
            tabs: const [
              Tab(text: 'Pending Trips'),
              Tab(text: 'On Going Trip'),
            ],
          ),
        ),
        body:  Column(
          children: [
            if (_currentTabIndex == 0)
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
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _isLoadingPending
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                    onRefresh: _fetchPendingDeliveries,
                    child: _buildPendingDeliveriesListView(
                      deliveries: _searchController.text.isEmpty
                          ? _pendingDeliveries
                          : _searchResults,
                      showAcceptDecline: _userRole == 'EMPLOYEE',
                    ),
                  ),

                  //Tab: In Progress Deliveries
                  _isLoadingInProgress
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                    onRefresh: _fetchInProgressDeliveries,
                    child: _inProgressDeliveries.isEmpty
                        ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(
                          height: 400, // Altura mínima para permitir scroll
                          child: Center(
                            child: Text(
                              'No active delivery',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    )
                        : ListView(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        _buildInProgressDeliveryCard(_inProgressDeliveries.first),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      floatingActionButton: (_userRole == 'COMPANY' && _currentTabIndex == 0)
          ? FloatingActionButton(
        onPressed: _navigateToCreateDelivery,
        backgroundColor: Colors.lightGreen,
        child: const Icon(Icons.add),
        tooltip: 'Create new delivery',
      )
          : null,
    );
  }

  Widget _buildPendingDeliveriesListView({
    required List<Deliveries> deliveries,
    required bool showAcceptDecline,
  }) {
    if (deliveries.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 400,
            child: Center(
              child: Text(
                'No deliveries to show',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: deliveries.length,
      itemBuilder: (context, index) {
        return _buildPendingDeliveryCard(
          delivery: deliveries[index],
          showAcceptDecline: showAcceptDecline,
        );
      },
    );
  }

  Widget _buildInProgressDeliveryCard(Deliveries delivery) {
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
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeliveryInProgressScreenScreen(deliveryId: delivery.id!),
                        ),
                      );

                      if (result == true) {
                        // Regresa al tab de "Pending Trips"
                        _tabController.animateTo(0);
                        _fetchPendingDeliveries();
                        _fetchInProgressDeliveries();
                      }
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

  Widget _buildPendingDeliveryCard({
    required Deliveries delivery,
    required bool showAcceptDecline, // true para EMPLOYEE, false para COMPANY
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeliveryDetailScreen(deliveryId: delivery.id!),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.lightGreen,
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                delivery.destination,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 4),
              Text(
                delivery.packageDescription,
                style: const TextStyle(fontSize: 18, color: Colors.black87),
              ),
              const SizedBox(height: 16),

              //Botones para EMPLOYEE
              if (showAcceptDecline)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () => _declineDelivery(delivery.id!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('DECLINE', style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final userId = prefs.getInt('userId');
                        final employeeId = await _employeeService.getEmployeeIdByUserId(userId!);
                        final activeDeliveries = await _deliveriesService.getDeliveryByEmployeeId(employeeId);

                        final hasInProgress = activeDeliveries.any((d) => d.state == 'IN_PROGRESS');

                        if (hasInProgress) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('You already have a delivery in progress')),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeliveryDetailScreen(deliveryId: delivery.id!),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('ACCEPT', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),

              // Botones para COMPANY
              if (!showAcceptDecline)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _confirmDeleteDelivery(delivery.id!),
                      icon: const Icon(Icons.delete, color: Colors.white,),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      label: const Text('DELETE', style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeliveryDetailScreen(deliveryId: delivery.id!),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility, color: Colors.black,),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      label: const Text('VIEW', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
