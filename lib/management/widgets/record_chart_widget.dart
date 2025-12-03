import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/record.dart';

/// Tipos de gráficos disponibles
enum ChartType { temperature, gas, heartbeat, location }

/**
 * Widget con tabs para mostrar gráficos individuales de cada sensor
 * incluyendo un mapa para la ubicación GPS
 */
class RecordChart extends StatefulWidget {
  final List<RecordLog> records;

  const RecordChart({Key? key, required this.records}) : super(key: key);

  @override
  State<RecordChart> createState() => _RecordChartState();
}

class _RecordChartState extends State<RecordChart> {
  ChartType _selectedChart = ChartType.temperature;

  @override
  Widget build(BuildContext context) {
    if (widget.records.isEmpty) {
      return const Center(child: Text('There is no data to display'));
    }

    return Column(
      children: [
        // Botones de selección
        _buildChartSelector(),
        const SizedBox(height: 16),
        // Gráfico seleccionado
        _buildSelectedChart(),
      ],
    );
  }

  Widget _buildChartSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildSelectorButton(
            type: ChartType.temperature,
            label: '°C',
            icon: Icons.thermostat,
            color: Colors.red,
          ),
          _buildSelectorButton(
            type: ChartType.gas,
            label: '%',
            icon: Icons.cloud,
            color: Colors.blue,
          ),
          _buildSelectorButton(
            type: ChartType.heartbeat,
            label: 'BPM',
            icon: Icons.favorite,
            color: Colors.green,
          ),
          _buildSelectorButton(
            type: ChartType.location,
            label: 'GPS',
            icon: Icons.location_on,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorButton({
    required ChartType type,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedChart == type;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedChart = type;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected 
                ? Border.all(color: color, width: 2)
                : Border.all(color: Colors.transparent, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? color : Colors.grey,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedChart() {
    final records = List<RecordLog>.from(widget.records);
    records.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final startTime = records.first.timestamp;
    final endTime = records.last.timestamp;
    final totalMinutes = endTime.difference(startTime).inMinutes.toDouble();

    switch (_selectedChart) {
      case ChartType.temperature:
        return _buildSingleChart(
          records: records,
          startTime: startTime,
          totalMinutes: totalMinutes,
          getValue: (r) => r.temperatureValue,
          color: Colors.red,
          title: 'Temperature',
          minY: -10,
          maxY: 50,
          unit: '°C',
          icon: Icons.thermostat,
        );
      case ChartType.gas:
        return _buildSingleChart(
          records: records,
          startTime: startTime,
          totalMinutes: totalMinutes,
          getValue: (r) => r.gasValue,
          color: Colors.blue,
          title: 'Gas Level',
          minY: 0,
          maxY: 100,
          unit: '%',
          icon: Icons.cloud,
        );
      case ChartType.heartbeat:
        return _buildSingleChart(
          records: records,
          startTime: startTime,
          totalMinutes: totalMinutes,
          getValue: (r) => r.heartRateValue,
          color: Colors.green,
          title: 'Heart Rate',
          minY: 0,
          maxY: 200,
          unit: 'BPM',
          icon: Icons.favorite,
        );
      case ChartType.location:
        return _buildLocationView(records);
    }
  }

  Widget _buildSingleChart({
    required List<RecordLog> records,
    required DateTime startTime,
    required double totalMinutes,
    required double Function(RecordLog) getValue,
    required Color color,
    required String title,
    required double minY,
    required double maxY,
    required String unit,
    required IconData icon,
  }) {
    final interval = totalMinutes > 0 
        ? (totalMinutes / 6).ceilToDouble().clamp(1, 60)
        : 1.0;

    String formatXAxisLabel(double value) {
      if (totalMinutes <= 0) return '0';
      final timestamp = startTime.add(Duration(minutes: value.toInt()));
      if (totalMinutes <= 60) {
        return '${value.toInt()}m';
      } else {
        final h = timestamp.hour.toString().padLeft(2, '0');
        final m = timestamp.minute.toString().padLeft(2, '0');
        return '$h:$m';
      }
    }

    List<FlSpot> spots = records.map((r) {
      final x = (r.timestamp.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch) / 60000;
      return FlSpot(x, getValue(r));
    }).toList();

    // Calcular min/max dinámico basado en los datos
    final values = records.map((r) => getValue(r)).toList();
    final dataMin = values.reduce((a, b) => a < b ? a : b);
    final dataMax = values.reduce((a, b) => a > b ? a : b);
    
    // Ajustar el rango para que los datos se vean bien
    final padding = (dataMax - dataMin) * 0.2;
    final dynamicMinY = (dataMin - padding).clamp(minY, dataMax - 1);
    final dynamicMaxY = (dataMax + padding).clamp(dataMin + 1, maxY);

    // Valor actual (último registro)
    final currentValue = getValue(records.last);

    return Column(
      children: [
        // Header con valor actual y unidad
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  '${currentValue.toStringAsFixed(1)} $unit',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Gráfico
        SizedBox(
          height: 220,
          child: Padding(
            padding: const EdgeInsets.only(right: 16, left: 8, top: 8, bottom: 8),
            child: LineChart(
              LineChartData(
                minY: dynamicMinY,
                maxY: dynamicMaxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: color,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.15),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: interval.toDouble(),
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          formatXAxisLabel(value),
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(
                      unit,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    axisNameSize: 20,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      interval: (dynamicMaxY - dynamicMinY) / 5,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: (dynamicMaxY - dynamicMinY) / 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[300],
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.grey[300],
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(1)} $unit',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationView(List<RecordLog> records) {
    final lastRecord = records.last;
    final lat = lastRecord.latitude;
    final lng = lastRecord.longitude;

    return Column(
      children: [
        // Header con coordenadas actuales
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        // Coordenadas
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  const Text(
                    'Latitude',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lat.toStringAsFixed(4),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              Container(
                height: 30,
                width: 1,
                color: Colors.orange.withOpacity(0.3),
              ),
              Column(
                children: [
                  const Text(
                    'Longitude',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lng.toStringAsFixed(4),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Mapa
        Container(
          height: 250,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(lat, lng),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.fastflow_app',
              ),
              MarkerLayer(
                markers: [
                  // Marcador de ubicación actual
                  Marker(
                    point: LatLng(lat, lng),
                    width: 50,
                    height: 50,
                    child: const _PulsingMarker(),
                  ),
                  // Ruta de ubicaciones previas
                  ...records.asMap().entries.map((entry) {
                    final index = entry.key;
                    final record = entry.value;
                    // Solo mostrar marcadores pequeños para posiciones anteriores
                    if (index == records.length - 1) {
                      return Marker(
                        point: LatLng(0, 0), // Placeholder, el marcador principal ya está arriba
                        width: 0,
                        height: 0,
                        child: const SizedBox.shrink(),
                      );
                    }
                    return Marker(
                      point: LatLng(record.latitude, record.longitude),
                      width: 12,
                      height: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.6),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
              // Línea de ruta si hay múltiples puntos
              if (records.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: records.map((r) => LatLng(r.latitude, r.longitude)).toList(),
                      color: Colors.orange.withOpacity(0.7),
                      strokeWidth: 3,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Marcador pulsante para la ubicación actual
class _PulsingMarker extends StatefulWidget {
  const _PulsingMarker();

  @override
  State<_PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<_PulsingMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Círculo pulsante exterior
            Transform.scale(
              scale: _animation.value,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Marcador principal
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.navigation,
                color: Colors.white,
                size: 12,
              ),
            ),
          ],
        );
      },
    );
  }
}
