class RecordLog {
  final int? id; // Opcional porque el backend puede no devolverlo en algunos casos
  final int sensorId;
  final int deliveryId;
  final DateTime timestamp;
  final double temperatureValue;
  final double gasValue;
  final double heartRateValue;
  final double latitude;
  final double longitude;

  RecordLog({
    this.id,
    required this.sensorId,
    required this.deliveryId,
    required this.timestamp,
    required this.temperatureValue,
    required this.gasValue,
    required this.heartRateValue,
    required this.latitude,
    required this.longitude,
  });

  factory RecordLog.fromJson(Map<String, dynamic> json) {
    // El timestamp puede venir como array o como string ISO
    DateTime parsedTimestamp;
    if (json['timestamp'] == null) {
      // Si no hay timestamp, usar el actual
      parsedTimestamp = DateTime.now();
    } else if (json['timestamp'] is String) {
      parsedTimestamp = DateTime.parse(json['timestamp']);
    } else if (json['timestamp'] is List) {
      final List<dynamic> ts = json['timestamp'];
      final hasNanos = ts.length >= 7;
      final millisecond = hasNanos ? (ts[6] / 1000000).round() : 0;
      parsedTimestamp = DateTime(ts[0], ts[1], ts[2], ts[3], ts[4], ts[5], millisecond);
    } else {
      // Fallback al timestamp actual
      parsedTimestamp = DateTime.now();
    }

    return RecordLog(
      id: json['id'],
      sensorId: json['sensorId'] ?? 0,
      deliveryId: json['deliveryId'] ?? 0,
      temperatureValue: ((json['temperatureValue'] ?? 0) as num).toDouble(),
      gasValue: ((json['gasValue'] ?? 0) as num).toDouble(),
      heartRateValue: ((json['heartRateValue'] ?? 0) as num).toDouble(),
      latitude: ((json['latitude'] ?? 0.0) as num).toDouble(),
      longitude: ((json['longitude'] ?? 0.0) as num).toDouble(),
      timestamp: parsedTimestamp,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'sensorId': sensorId,
      'deliveryId': deliveryId,
      'gasValue': gasValue,
      'heartRateValue': heartRateValue,
      'temperatureValue': temperatureValue,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
    // Solo incluir id si está presente
    if (id != null) {
      json['id'] = id!;
    }
    return json;
  }
}