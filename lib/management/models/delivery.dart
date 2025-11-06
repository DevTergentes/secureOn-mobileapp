class Deliveries {
  final int? id; // `id` es opcional para cuando se crea una nueva entrega
  final String destination;
  final String packageDescription;
  final String exitPoint;
  final String route;
  final String stop;
  final String combustibleType;
  final int? employeeId;    // puede estar vacío al crear
  final int ownerId;        // obligatorio (quién lo creó)
  final String state;


  Deliveries({
    this.id,
    required this.destination,
    required this.packageDescription,
    required this.exitPoint,
    required this.route,
    required this.stop,
    required this.combustibleType,
    this.employeeId,
    required this.ownerId,
    required this.state,
  });

  // Constructor para crear una instancia desde JSON
  factory Deliveries.fromJson(Map<String, dynamic> json) {
    return Deliveries(
      id: json['id'],
      destination: json['destination'],
      packageDescription: json['packageDescription'],
      exitPoint: json['exitPoint'],
      route: json['route'],
      stop: json['stop'],
      combustibleType: json['combustibleType'],
      employeeId: json['employeeId'],
      ownerId: json['ownerId'],
      state: json['state'],
    );
  }

  // Método para convertir el objeto a JSON
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      "destination": destination,
      "packageDescription": packageDescription,
      "exitPoint": exitPoint,
      "route": route,
      "stop": stop,
      "combustibleType": combustibleType,
      "ownerId": ownerId,
      "state": state,
    };
    // Solo incluir campos opcionales si están presentes
    if (id != null) json["id"] = id;
    if (employeeId != null && employeeId != 0) json["employeeId"] = employeeId;
    return json;
  }
}
