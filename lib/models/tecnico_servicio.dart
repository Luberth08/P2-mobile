// Modelos para la sección de técnicos

class TallerTecnicoInfo {
  final int id;
  final String nombre;
  final int serviciosActivos;

  TallerTecnicoInfo({
    required this.id,
    required this.nombre,
    required this.serviciosActivos,
  });

  factory TallerTecnicoInfo.fromJson(Map<String, dynamic> json) {
    return TallerTecnicoInfo(
      id: json['id'],
      nombre: json['nombre'],
      serviciosActivos: json['servicios_activos'],
    );
  }
}

class ClienteServicioInfo {
  final String nombre;
  final String? telefono;
  final double ubicacionLat;
  final double ubicacionLon;

  ClienteServicioInfo({
    required this.nombre,
    this.telefono,
    required this.ubicacionLat,
    required this.ubicacionLon,
  });

  factory ClienteServicioInfo.fromJson(Map<String, dynamic> json) {
    return ClienteServicioInfo(
      nombre: json['nombre'],
      telefono: json['telefono'],
      ubicacionLat: (json['ubicacion_lat'] as num).toDouble(),
      ubicacionLon: (json['ubicacion_lon'] as num).toDouble(),
    );
  }
}

class VehiculoAsignadoTecnico {
  final int idVehiculoTaller;
  final String matricula;
  final String marca;
  final String modelo;

  VehiculoAsignadoTecnico({
    required this.idVehiculoTaller,
    required this.matricula,
    required this.marca,
    required this.modelo,
  });

  factory VehiculoAsignadoTecnico.fromJson(Map<String, dynamic> json) {
    return VehiculoAsignadoTecnico(
      idVehiculoTaller: json['id_vehiculo_taller'],
      matricula: json['matricula'],
      marca: json['marca'],
      modelo: json['modelo'],
    );
  }
}

class DiagnosticoServicioInfo {
  final int id;
  final String? descripcion;
  final double nivelConfianza;
  final DateTime fecha;

  DiagnosticoServicioInfo({
    required this.id,
    this.descripcion,
    required this.nivelConfianza,
    required this.fecha,
  });

  factory DiagnosticoServicioInfo.fromJson(Map<String, dynamic> json) {
    return DiagnosticoServicioInfo(
      id: json['id'],
      descripcion: json['descripcion'],
      nivelConfianza: (json['nivel_confianza'] as num).toDouble(),
      fecha: DateTime.parse(json['fecha']),
    );
  }
}

class ServicioTecnico {
  final int id;
  final DateTime fecha;
  final String estado;
  final String estadoDescripcion;
  final ClienteServicioInfo cliente;
  final DiagnosticoServicioInfo diagnostico;
  final List<VehiculoAsignadoTecnico> vehiculosAsignados;
  final String tallerNombre;
  final double? distanciaClienteKm;

  ServicioTecnico({
    required this.id,
    required this.fecha,
    required this.estado,
    required this.estadoDescripcion,
    required this.cliente,
    required this.diagnostico,
    required this.vehiculosAsignados,
    required this.tallerNombre,
    this.distanciaClienteKm,
  });

  factory ServicioTecnico.fromJson(Map<String, dynamic> json) {
    return ServicioTecnico(
      id: json['id'],
      fecha: DateTime.parse(json['fecha']),
      estado: json['estado'],
      estadoDescripcion: json['estado_descripcion'],
      cliente: ClienteServicioInfo.fromJson(json['cliente']),
      diagnostico: DiagnosticoServicioInfo.fromJson(json['diagnostico']),
      vehiculosAsignados: (json['vehiculos_asignados'] as List)
          .map((v) => VehiculoAsignadoTecnico.fromJson(v))
          .toList(),
      tallerNombre: json['taller_nombre'],
      distanciaClienteKm: json['distancia_cliente_km']?.toDouble(),
    );
  }

  String get estadoColor {
    switch (estado) {
      case 'tecnico_asignado':
        return '#3B82F6'; // Azul
      case 'en_camino':
        return '#F59E0B'; // Amarillo
      case 'en_lugar':
        return '#8B5CF6'; // Púrpura
      case 'en_atencion':
        return '#EF4444'; // Rojo
      case 'finalizado':
        return '#10B981'; // Verde
      case 'cancelado':
        return '#6B7280'; // Gris
      default:
        return '#6B7280';
    }
  }

  String get estadoIcono {
    switch (estado) {
      case 'tecnico_asignado':
        return '👨‍🔧';
      case 'en_camino':
        return '🚗';
      case 'en_lugar':
        return '📍';
      case 'en_atencion':
        return '🔧';
      case 'finalizado':
        return '✅';
      case 'cancelado':
        return '❌';
      default:
        return '❓';
    }
  }

  bool get puedeActualizarUbicacion {
    return ['tecnico_asignado', 'en_camino', 'en_lugar', 'en_atencion'].contains(estado);
  }

  List<String> get siguientesEstados {
    switch (estado) {
      case 'tecnico_asignado':
        return ['en_camino'];
      case 'en_camino':
        return ['en_lugar'];
      case 'en_lugar':
        return ['en_atencion'];
      case 'en_atencion':
        return ['finalizado'];
      default:
        return [];
    }
  }
}

enum EstadoServicioTecnico {
  tecnicoAsignado,
  enCamino,
  enLugar,
  enAtencion,
  finalizado,
  cancelado,
}

extension EstadoServicioTecnicoExtension on EstadoServicioTecnico {
  String get value {
    switch (this) {
      case EstadoServicioTecnico.tecnicoAsignado:
        return 'tecnico_asignado';
      case EstadoServicioTecnico.enCamino:
        return 'en_camino';
      case EstadoServicioTecnico.enLugar:
        return 'en_lugar';
      case EstadoServicioTecnico.enAtencion:
        return 'en_atencion';
      case EstadoServicioTecnico.finalizado:
        return 'finalizado';
      case EstadoServicioTecnico.cancelado:
        return 'cancelado';
    }
  }

  String get descripcion {
    switch (this) {
      case EstadoServicioTecnico.tecnicoAsignado:
        return 'Técnico Asignado';
      case EstadoServicioTecnico.enCamino:
        return 'En Camino';
      case EstadoServicioTecnico.enLugar:
        return 'En el Lugar';
      case EstadoServicioTecnico.enAtencion:
        return 'En Atención';
      case EstadoServicioTecnico.finalizado:
        return 'Finalizado';
      case EstadoServicioTecnico.cancelado:
        return 'Cancelado';
    }
  }
}