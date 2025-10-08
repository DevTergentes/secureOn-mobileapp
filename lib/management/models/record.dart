class RecordLog {
  final int id;
  final int sensorId;
  final int deliveryId;
  final DateTime timestamp;
  final double temperatureValue;
  final double gasValue;
  final double heartRateValue;
  final double latitude;
  final double longitude;

  RecordLog({
    required this.id,
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
    final List<dynamic> ts = json['timestamp'];       // alias corto

    // Si el backend a veces envía [y,m,d,h,min,sec] y a veces [y,m,d,h,min,sec,nanos]
    final hasNanos = ts.length >= 7;
    final millisecond = hasNanos ? (ts[6] / 1000000).round() : 0;

    return RecordLog(
      id: json['id'],
      sensorId: json['sensorId'],
      deliveryId: json['deliveryId'],
      temperatureValue: (json['temperatureValue'] as num).toDouble(),
      gasValue: (json['gasValue'] as num).toDouble(),
      heartRateValue: (json['heartRateValue'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime(ts[0], ts[1], ts[2], ts[3], ts[4], ts[5], millisecond),
    );
  }

}