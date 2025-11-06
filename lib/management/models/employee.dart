class Employee {
  final int? id; // Opcional para crear nuevos empleados
  final int userId;
  final String fullName;
  final int? companyId; // ID de la compañía a la que pertenece el empleado

  Employee({
    this.id,
    required this.userId,
    required this.fullName,
    this.companyId,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      userId: json['userId'],
      fullName: json['fullName'],
      companyId: json['companyId'],
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id ?? 0,
      'userId': userId,
      'fullName': fullName,
    };
    // Solo incluir companyId si está presente
    if (companyId != null) {
      json['companyId'] = companyId!;
    }
    return json;
  }
}

