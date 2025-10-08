import 'package:fastflow_app/incidents/models/incident.dart';
import 'package:fastflow_app/incidents/screens/add_incident_screen.dart';
import 'package:fastflow_app/incidents/services/incident_service.dart';
import 'package:fastflow_app/management/services/delivery_services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/**
 * muestra la lista de incidentes de un delivery, permite añadir un incidente (employee)
 * y eliminar un incidente (company)
 */
class IncidentsListScreen extends StatefulWidget {
  final int deliveryId;
  const IncidentsListScreen({required this.deliveryId,super.key});

  @override
  _IncidentsListScreenState createState() => _IncidentsListScreenState();
}

class _IncidentsListScreenState extends State<IncidentsListScreen> {
  final IncidentsService _incidentsService = IncidentsService();
  final DeliveriesService _deliveriesService = DeliveriesService();
  List<Incident> _incidents = [];
  List<Incident> _searchResults = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String? _deliveryState;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadIncidentsIfInProgress();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    String searchQuery = _searchController.text.toLowerCase();
    setState(() {
      _searchResults = _incidents.where((incident) {
        return incident.incidentPlace.toLowerCase().contains(searchQuery) ||
               incident.description.toLowerCase().contains(searchQuery);
      }).toList();
    });
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role');
    });
  }

  Future<void> _loadIncidentsIfInProgress() async {
    setState(() => _isLoading = true);

    try {
      final state = await _deliveriesService.getDeliveryState(widget.deliveryId);
      final incidents = await _incidentsService.getIncidentsByDelivery(widget.deliveryId);

      setState(() {
        _deliveryState = state;
        _incidents = incidents;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteIncident(int id) async {
    try {
      await _incidentsService.deleteIncident(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incident eliminated')),
      );
      _loadIncidentsIfInProgress(); // recarga la lista
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting: $e')),
      );
    }
  }


  Future<void> _navigateToAddIncident() async {
    bool? added = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddIncidentScreen(deliveryId: widget.deliveryId,)),
    );

    if (added == true) {
      _loadIncidentsIfInProgress(); // Actualiza la lista después de añadir un incidente
    }
  }

  void _confirmDeleteIncident(int incidentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete incident'),
        content: const Text('Are you sure you want to delete this incident?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteIncident(incidentId);
              _loadIncidentsIfInProgress();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incidents for delivery', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deliveryState == null
          ? const Center(child: Text('Unable to determine delivery state.'))
          : RefreshIndicator(
        onRefresh: _loadIncidentsIfInProgress,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search for incidents...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                  ),
                ),
              ),
            ),
            if (_incidents.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Text('No incidents recorded yet.'),
                ),
              )
            else
              ...(_searchController.text.isNotEmpty || _searchResults.isNotEmpty
                  ? _searchResults
                  : _incidents)
                  .map((incident) => _buildIncidentCard(incident))
          ],
        ),
      ),
      floatingActionButton: _userRole == 'EMPLOYEE' && _deliveryState == 'IN_PROGRESS'
          ? FloatingActionButton(
        onPressed: _navigateToAddIncident,
        backgroundColor: Colors.lightGreen,
        child: const Icon(Icons.add),
      )
          : null,
    );
  }

  Widget _buildIncidentsList(List<Incident> incidents) {
    return ListView.builder(
      itemCount: incidents.length,
      itemBuilder: (context, index) {
        return _buildIncidentCard(incidents[index]);
      },
    );
  }

  Widget _buildIncidentCard(Incident incident) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.red,
              child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    incident.incidentPlace,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Description: ${incident.description}",
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _userRole == 'COMPANY' && _deliveryState == 'COMPLETED'
                ? IconButton(
              icon: const Icon(Icons.delete, color: Colors.black),
              tooltip: 'Delete incident',
              onPressed: () {
                if (incident.id != null) {
                  _confirmDeleteIncident(incident.id!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('This incident does not have a valid ID')),
                  );
                }
              }
            )
                : Text(
              DateFormat('dd-MM HH:mm').format(incident.date),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),

      ),
    );
  }
}
