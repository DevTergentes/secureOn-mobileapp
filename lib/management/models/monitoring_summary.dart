import 'package:fastflow_app/management/models/record.dart';

class MonitoringSummary {
  final RecordLog record;
  final int monitoringMinutes;
  final bool safe;

  MonitoringSummary({
    required this.record,
    required this.monitoringMinutes,
    required this.safe,
  });
}