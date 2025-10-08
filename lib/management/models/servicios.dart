class Servicios {
  final int? id; // Cambiado a `int?` para permitir que sea nulo cuando se crea un nuevo servicio
  final String nameService;
  final String description;
  final int ownerId;
  final int deliveryId;

  Servicios({
    this.id,
    required this.nameService,
    required this.description,
    required this.ownerId,
    required this.deliveryId,
  });

  Servicios.fromJson(Map<String, dynamic> map)
      : id = map["id"],
        nameService = map["nameService"],
        description = map["description"],
        ownerId = map["ownerId"],
        deliveryId = map["deliveryId"];

  // Método para convertir el objeto a JSON
  Map<String, dynamic> toJson() {
    return {
      "nameService": nameService,
      "description": description,
      "ownerId": ownerId,
      "deliveryId": deliveryId,
    };
  }
}
