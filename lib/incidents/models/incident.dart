class Incident {
  final int? id; // `id` es opcional para permitir nuevos incidentes
  final String incidentPlace;
  final DateTime date;
  final String description;
  final int deliveryId;

  Incident({
    this.id,
    required this.incidentPlace,
    required this.date,
    required this.description,
    required this.deliveryId,
  });

  Map<String, dynamic> toJson() {
    return {
      'incidentPlace': incidentPlace,
      'date': [
        date.year,
        date.month,
        date.day,
        date.hour,
        date.minute,
        date.second,
        date.microsecond * 1000
      ],
      'description': description,
      'serviceId': deliveryId
    };
  }

  factory Incident.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dateList = json['date'];
    final DateTime parsedDate = DateTime(
      dateList[0],
      dateList[1],
      dateList[2],
      dateList[3],
      dateList[4],
      dateList[5],
      (dateList[6] / 1000).round(), // nanosegundos a microsegundos
    );

    return Incident(
      id: json['id'],
      incidentPlace: json['incidentPlace'],
      date: parsedDate,
      description: json['description'],
      deliveryId: json['serviceId'],
    );
  }
}
