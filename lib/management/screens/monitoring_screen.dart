import 'package:fastflow_app/management/models/monitoring_summary.dart';
import 'package:flutter/material.dart';
import '../models/record.dart';
import '../services/delivery_services.dart';
import '../services/record_service.dart';
import '../widgets/record_chart_widget.dart';
import '../widgets/legend_item_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _loadMonitoringSummary();
  }

  Future<void> _loadMonitoringSummary() async {
    setState(() { _isLoading = true; });
    try {
      MonitoringSummary summary = await _recordService.getMonitoringSummary(widget.deliveryId);
      final records = await _recordService.getAllRecords(widget.deliveryId);
      print("SUMMARY: $summary");
      print("RECORDS: $records");
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      print("ERROR: $e");
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

  @override
  Widget build(BuildContext context) {
    // Aquí el arreglo seguro para el gráfico:
    final recordsToShow = _records.length > 6 ? _records.sublist(_records.length - 6) : _records;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _summary == null
          ? const Center(child: Text('No monitoring data available'))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            const Text(
              'Last Sensor values',
              style: TextStyle(
                  fontSize: 22,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold
              ),
            ),
            const Divider(height: 32, color: Colors.lightGreen),
            const SizedBox(height: 8),
            Text(
              'Gas: ${_summary!.record.gasValue}',
              style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black87),
            ),
            Text('Temperature: ${_summary!.record.temperatureValue} °C',
              style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black87),),
            Text('BPM: ${_summary!.record.heartRateValue}',
              style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black87),),
            const SizedBox(height: 8),
            Text(
              _summary!.safe ? 'Safe sensor' : 'Unsafe sensor',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _summary!.safe ? Colors.green : Colors.red
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 32, color: Colors.lightGreen),
            const Text(
              'Monitoring Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('${_summary!.monitoringMinutes} minutes',
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black87)),
            const SizedBox(height: 24),
            const Text(
              'Sensor Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: RecordChart(records: recordsToShow),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  LegendItem(color: Colors.red, label: 'Temperature'),
                  LegendItem(color: Colors.blue, label: 'Gas'),
                  LegendItem(color: Colors.green, label: 'Heartbeat'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
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
}
