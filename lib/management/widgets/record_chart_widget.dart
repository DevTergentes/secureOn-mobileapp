import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/record.dart';

/**
 * muestra un grafico con los ultimos datos de monitoreo de un sensor dependiendo de la cantidad de minutos
 * entre la primera y ultima lectura convertido a horas o minutos
 */
class RecordChart extends StatelessWidget {
  final List<RecordLog> records;

  const RecordChart({Key? key, required this.records}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(child: Text('There is no data to display'));
    }

    records.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final startTime = records.first.timestamp;
    final endTime = records.last.timestamp;
    final totalMinutes = endTime.difference(startTime).inMinutes.toDouble();

    final interval = (totalMinutes / 6).ceilToDouble().clamp(1, 60);

    String formatXAxisLabel(double value) {
      final timestamp = startTime.add(Duration(minutes: value.toInt()));
      if (totalMinutes <= 60) {
        return '${value.toInt()} min';
      } else {
        final h = timestamp.hour.toString().padLeft(2, '0');
        final m = timestamp.minute.toString().padLeft(2, '0');
        return '$h:$m';
      }
    }


    List<FlSpot> temperatureSpots = records.map((r) {
      final x = (r.timestamp.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch) / 60000; // minutos
      return FlSpot(x, r.temperatureValue);
    }).toList();

    List<FlSpot> gasSpots = records.map((r) {
      final x = (r.timestamp.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch) / 60000;
      return FlSpot(x, r.gasValue);
    }).toList();

    List<FlSpot> heartRateSpots = records.map((r) {
      final x = (r.timestamp.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch) / 60000;
      return FlSpot(x, r.heartRateValue.toDouble());
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            _buildLine(temperatureSpots, Colors.red, 'Temperature'),
            _buildLine(gasSpots, Colors.blue, 'Gas'),
            _buildLine(heartRateSpots, Colors.green, 'Heartbeat'),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval.toDouble(),
                reservedSize: 32,
                getTitlesWidget: (value, meta) => Transform.rotate(
                  angle: -0.5,
                  child: Text(
                    formatXAxisLabel(value),
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(0)),
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: true),
        ),
      ),
    );
  }

  LineChartBarData _buildLine(List<FlSpot> spots, Color color, String label) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(show: false),
    );
  }
}