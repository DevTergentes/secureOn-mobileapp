import 'dart:async';
import 'package:fastflow_app/iam/screens/signup_screen.dart';
import 'package:fastflow_app/management/models/servicios.dart';
import 'package:fastflow_app/management/services/servicios_service.dart';
import 'package:fastflow_app/management/screens/servicios_add_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'delivery_detail_screen.dart';

class ServiciosListScreen extends StatefulWidget {
  const ServiciosListScreen({super.key});

  @override
  _ServiciosListScreenState createState() => _ServiciosListScreenState();
}

class _ServiciosListScreenState extends State<ServiciosListScreen> {
  final ServiciosService _serviciosService = ServiciosService();
  List<Servicios> _services = [];
  List<Servicios> _searchResults = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchServices();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchServices() async {
    try {
      List<Servicios> services = await _serviciosService.getAll();
      setState(() {
        _services = services;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _confirmDeleteService(int serviceId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Service'),
        content: const Text('Are you sure you want to delete this service?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteService(serviceId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteService(int serviceId) async {
    try {
      await _serviciosService.deleteService(serviceId);
      _fetchServices(); // recarga la lista
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting service: $e')),
      );
    }
  }

  void _onSearchChanged() {
    String searchQuery = _searchController.text.toLowerCase();
    setState(() {
      if (searchQuery.isEmpty) {
        _searchResults.clear();
      } else {
        _searchResults = _services.where((service) {
          return service.nameService.toLowerCase().contains(searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _navigateToAddService(int deliveryId) async {
    bool? added = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ServiciosAddScreen(deliveryId: deliveryId,)),
    );

    if (added == true) {
      _fetchServices(); // Actualiza la lista después de añadir un servicio
    }
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Services',
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
                            'Find your service',
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
                                    hintText: 'Search for a service...',
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
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Services On Going',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                  ),
                  _searchController.text.isNotEmpty
                      ? _buildSearchResults()
                      : _buildServicesList(),
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
        return _buildServiceTile(_searchResults[index]);
      },
    );
  }

  Widget _buildServicesList() {
    if (_services.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No services available.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        return _buildServiceTile(_services[index]);
      },
    );
  }

  Widget _buildServiceTile(Servicios service) {
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
        leading: ClipOval(
          child: Image.asset(
            'assets/safe.png',
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          service.nameService,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              service.description.length > 50
                  ? '${service.description.substring(0, 50)}...'
                  : service.description,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Delivery ID: ${service.deliveryId}',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmDeleteService(service.id!),
          tooltip: 'Delete Service',
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DeliveryDetailScreen(deliveryId: service.deliveryId),
            ),
          );
        },
      ),
    );
  }
}
