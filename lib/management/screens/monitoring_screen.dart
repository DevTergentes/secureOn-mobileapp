import 'dart:async';
import 'package:fastflow_app/management/models/monitoring_summary.dart';
import 'package:flutter/material.dart';
import '../models/record.dart';
import '../services/delivery_services.dart';
import '../services/record_service.dart';
import '../widgets/record_chart_widget.dart';

/**
 * muestra los ultimos datos de monitoreo de un sensor y un grafico de los datos obtenidos
 */
class DeliveryInProgressScreenScreen extends StatefulWidget {
  final int deliveryId;
  const DeliveryInProgressScreenScreen({required this.deliveryId, super.key});

  @override
  _DeliveryInProgressScreenScreenState createState() => _DeliveryInProgressScreenScreenState();
}

class _DeliveryInProgressScreenScreenState extends State<DeliveryInProgressScreenScreen> {
  final RecordService _recordService = RecordService();
  final DeliveriesService _deliveriesService = DeliveriesService();
  MonitoringSummary? _summary;
  bool _isLoading = true;
  bool _isCompletingDelivery = false;
  List<RecordLog> _records = [];
  Timer? _refreshTimer;
  DateTime? _lastUpdate;

  @override
  void initState() {
    super.initState();
    _loadMonitoringSummary();
    // Refrescar automáticamente cada 2 segundos para datos más en tiempo real
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        _loadMonitoringSummary();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMonitoringSummary() async {
    // No mostrar loading si ya hay datos (para refresh automático)
    if (_summary == null) {
      setState(() { _isLoading = true; });
    }
    try {
      MonitoringSummary summary = await _recordService.getMonitoringSummary(widget.deliveryId);
      final records = await _recordService.getAllRecords(widget.deliveryId);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _records = records;
        _isLoading = false;
        _lastUpdate = DateTime.now();
      });
    } catch (e) {
      print("ERROR loading monitoring: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleEndDelivery() async {
    setState(() {
      _isCompletingDelivery = true;
    });

    try {
      await _deliveriesService.completeDelivery(widget.deliveryId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery completed successfully!')),
      );
      Navigator.of(context).pop(true);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete delivery: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isCompletingDelivery = false;
      });
    }
  }

  String _getTimeSinceLastUpdate() {
    if (_lastUpdate == null) return '';
    final diff = DateTime.now().difference(_lastUpdate!);
    if (diff.inSeconds < 5) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    return '${diff.inMinutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    final recordsToShow = _records.length > 10 ? _records.sublist(_records.length - 10) : _records;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Indicador de estado en tiempo real
          if (_summary != null)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _summary!.safe ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _summary!.safe ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _summary!.safe ? 'SAFE' : 'UNSAFE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _summary!.safe ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _summary == null || _records.isEmpty
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sensors_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No monitoring data available',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Waiting for sensor data...',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '📡 Configure in Wokwi:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'DELIVERY_ID = ${widget.deliveryId}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadMonitoringSummary,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadMonitoringSummary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Header con tiempo de monitoreo y última actualización
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.lightGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.lightGreen.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Icon(Icons.timer, color: Colors.lightGreen, size: 24),
                                const SizedBox(height: 4),
                                Text(
                                  '${_summary!.monitoringMinutes} min',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Monitoring',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            Container(
                              height: 40,
                              width: 1,
                              color: Colors.lightGreen.withOpacity(0.3),
                            ),
                            Column(
                              children: [
                                const Icon(Icons.update, color: Colors.lightGreen, size: 24),
                                const SizedBox(height: 4),
                                Text(
                                  _getTimeSinceLastUpdate(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Last update',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            Container(
                              height: 40,
                              width: 1,
                              color: Colors.lightGreen.withOpacity(0.3),
                            ),
                            Column(
                              children: [
                                const Icon(Icons.data_usage, color: Colors.lightGreen, size: 24),
                                const SizedBox(height: 4),
                                Text(
                                  '${_records.length}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Records',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Gráficos con selector de tipo
                      RecordChart(records: recordsToShow),
                      const SizedBox(height: 16),
                      // Indicador de actualización automática
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPulsingDot(),
                          const SizedBox(width: 8),
                          Text(
                            'Live updates every 2s',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isCompletingDelivery ? null : _handleEndDelivery,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightGreen,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
          ),
          child: _isCompletingDelivery
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('END DELIVERY', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildPulsingDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(value * 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
      onEnd: () {
        // Rebuild to restart animation
        if (mounted) setState(() {});
      },
    );
  }
}
