class Sensor {
  final int id;
  final int ownerId;
  final bool safe;

  Sensor({
    required this.id,
    required this.ownerId,
    required this.safe,

  });

  Sensor.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      ownerId = json['ownerId'],
      safe = json['safe'];

}