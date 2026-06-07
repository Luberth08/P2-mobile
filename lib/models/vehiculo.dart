class Vehiculo {
  final int id;
  final String marca;
  final String modelo;
  final String placa;

  Vehiculo({
    required this.id,
    required this.marca,
    required this.modelo,
    required this.placa,
  });

  factory Vehiculo.fromJson(Map<String, dynamic> json) {
    return Vehiculo(
      id: json['id'],
      marca: json['marca'] ?? '',
      modelo: json['modelo'] ?? '',
      placa: json['placa'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'marca': marca,
      'modelo': modelo,
      'placa': placa,
    };
  }
}
