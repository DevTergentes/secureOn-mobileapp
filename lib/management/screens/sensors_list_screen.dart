import 'dart:async';
import 'package:fastflow_app/iam/screens/signup_screen.dart';
import 'package:fastflow_app/management/models/sensor.dart';
import 'package:fastflow_app/management/services/sensor_service.dart';
import 'package:fastflow_app/management/screens/sensor_add_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main_screen.dart';

class SensorsListScreen extends StatefulWidget {
  const SensorsListScreen({super.key});

  @override
  _SensorsListScreenState createState() => _SensorsListScreenState();
}

class _SensorsListScreenState extends State<SensorsListScreen> {
  final SensorService _sensorService = SensorService();
  List<Sensor> _sensors = [];
  List<Sensor> _searchResults = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSensors();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSensors() async {
    try {
      List<Sensor> sensors = await _sensorService.getAllSensors();
      setState(() {
        _sensors = sensors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading sensors: $e')),
      );
    }
  }

  void _confirmDeleteSensor(int sensorId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Sensor'),
        content: const Text('Are you sure you want to delete this sensor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSensor(sensorId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSensor(int sensorId) async {
    try {
      await _sensorService.deleteSensor(sensorId);
      _fetchSensors(); // recarga la lista
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sensor deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting sensor: $e')),
      );
    }
  }

  void _onSearchChanged() {
    String searchQuery = _searchController.text.toLowerCase();
    setState(() {
      if (searchQuery.isEmpty) {
        _searchResults.clear();
      } else {
        _searchResults = _sensors.where((sensor) {
          return sensor.id.toString().contains(searchQuery) ||
                 sensor.ownerId.toString().contains(searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _navigateToAddSensor() async {
    bool? added = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SensorAddScreen()),
    );

    if (added == true) {
      _fetchSensors(); // Actualiza la lista después de añadir un sensor
    }
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
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddSensor,
        backgroundColor: Colors.lightGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchSensors,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Sensors',
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
                              'Find your sensor',
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
                                      hintText: 'Search by ID or Owner ID...',
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
                        'All Sensors',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                      ),
                    ),
                    _searchController.text.isNotEmpty
                        ? _buildSearchResults()
                        : _buildSensorsList(),
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
        child: Text('No sensors found.'),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildSensorTile(_searchResults[index]);
      },
    );
  }

  Widget _buildSensorsList() {
    if (_sensors.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No sensors available.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _sensors.length,
      itemBuilder: (context, index) {
        return _buildSensorTile(_sensors[index]);
      },
    );
  }

  Widget _buildSensorTile(Sensor sensor) {
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
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: sensor.safe ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
          child: Icon(
            sensor.safe ? Icons.check_circle : Icons.warning,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          'Sensor #${sensor.id ?? 'N/A'}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Owner ID: ${sensor.ownerId}',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: sensor.safe ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                sensor.safe ? 'Safe' : 'Unsafe',
                style: TextStyle(
                  color: sensor.safe ? Colors.green.shade800 : Colors.red.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () async {
                bool? updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SensorAddScreen(sensor: sensor),
                  ),
                );
                if (updated == true) {
                  _fetchSensors();
                }
              },
              tooltip: 'Edit Sensor',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDeleteSensor(sensor.id!),
              tooltip: 'Delete Sensor',
            ),
          ],
        ),
      ),
    );
  }
}

