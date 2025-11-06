class Sensor {
  final int? id; // Opcional para crear nuevos sensores
  final int ownerId;
  final bool safe;

  Sensor({
    this.id,
    required this.ownerId,
    required this.safe,
  });

  factory Sensor.fromJson(Map<String, dynamic> json) {
    return Sensor(
      id: json['id'],
      ownerId: json['ownerId'],
      safe: json['safe'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id ?? 0,
      'ownerId': ownerId,
      'safe': safe,
    };
  }
}