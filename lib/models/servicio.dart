// Modelos para Servicios del Cliente

class TallerInfo {
  final int id;
  final String nombre;
  final String? telefono;
  final String? email;
  final String? direccion;
  final String? ubicacion; // "lat,lon"
  final double puntos;

  TallerInfo({
    required this.id,
    required this.nombre,
    this.telefono,
    this.email,
    this.direccion,
    this.ubicacion,
    required this.puntos,
  });

  factory TallerInfo.fromJson(Map<String, dynamic> json) {
    return TallerInfo(
      id: json['id'],
      nombre: json['nombre'],
      telefono: json['telefono'],
      email: json['email'],
      direccion: json['direccion'],
      ubicacion: json['ubicacion'],
      puntos: (json['puntos'] as num).toDouble(),
    );
  }

  Map<double, double>? get coordenadas {
    if (ubicacion == null) return null;
    final parts = ubicacion!.split(',');
    if (parts.length != 2) return null;
    return {
      double.parse(parts[0]): double.parse(parts[1])
    };
  }
}

class TecnicoAsignado {
  final int idEmpleado;
  final String nombreCompleto;

  TecnicoAsignado({
    required this.idEmpleado,
    required this.nombreCompleto,
  });

  factory TecnicoAsignado.fromJson(Map<String, dynamic> json) {
    return TecnicoAsignado(
      idEmpleado: json['id_empleado'],
      nombreCompleto: json['nombre_completo'],
    );
  }
}

class VehiculoAsignado {
  final int idVehiculoTaller;
  final String matricula;
  final String marca;
  final String modelo;

  VehiculoAsignado({
    required this.idVehiculoTaller,
    required this.matricula,
    required this.marca,
    required this.modelo,
  });

  factory VehiculoAsignado.fromJson(Map<String, dynamic> json) {
    return VehiculoAsignado(
      idVehiculoTaller: json['id_vehiculo_taller'],
      matricula: json['matricula'],
      marca: json['marca'],
      modelo: json['modelo'],
    );
  }
}

class DiagnosticoDetalle {
  final int id;
  final String? descripcion;
  final double nivelConfianza;
  final DateTime fecha;

  DiagnosticoDetalle({
    required this.id,
    this.descripcion,
    required this.nivelConfianza,
    required this.fecha,
  });

  factory DiagnosticoDetalle.fromJson(Map<String, dynamic> json) {
    return DiagnosticoDetalle(
      id: json['id'],
      descripcion: json['descripcion'],
      nivelConfianza: (json['nivel_confianza'] as num).toDouble(),
      fecha: DateTime.parse(json['fecha']),
    );
  }
}

class ServicioCliente {
  final int id;
  final DateTime fecha;
  final String estado;
  final TallerInfo taller;
  final List<TecnicoAsignado> tecnicosAsignados;
  final List<VehiculoAsignado> vehiculosAsignados;
  final String? ubicacionCliente; // "lat,lon"
  final DiagnosticoDetalle? diagnostico;

  ServicioCliente({
    required this.id,
    required this.fecha,
    required this.estado,
    required this.taller,
    required this.tecnicosAsignados,
    required this.vehiculosAsignados,
    this.ubicacionCliente,
    this.diagnostico,
  });

  factory ServicioCliente.fromJson(Map<String, dynamic> json) {
    return ServicioCliente(
      id: json['id'],
      fecha: DateTime.parse(json['fecha']),
      estado: json['estado'],
      taller: TallerInfo.fromJson(json['taller']),
      tecnicosAsignados: (json['tecnicos_asignados'] as List)
          .map((t) => TecnicoAsignado.fromJson(t))
          .toList(),
      vehiculosAsignados: (json['vehiculos_asignados'] as List)
          .map((v) => VehiculoAsignado.fromJson(v))
          .toList(),
      ubicacionCliente: json['ubicacion_cliente'],
      diagnostico: json['diagnostico'] != null
          ? DiagnosticoDetalle.fromJson(json['diagnostico'])
          : null,
    );
  }

  Map<double, double>? get coordenadasCliente {
    if (ubicacionCliente == null) return null;
    final parts = ubicacionCliente!.split(',');
    if (parts.length != 2) return null;
    return {
      double.parse(parts[0]): double.parse(parts[1])
    };
  }

  String get estadoTexto {
    switch (estado) {
      case 'creado':
        return 'Creado';
      case 'tecnico_asignado':
        return 'Técnico Asignado';
      case 'en_camino':
        return 'En Camino';
      case 'en_lugar':
        return 'En el Lugar';
      case 'en_atencion':
        return 'En Atención';
      case 'finalizado':
        return 'Finalizado';
      case 'cancelado':
        return 'Cancelado';
      // Estados antiguos para compatibilidad
      case 'en_proceso':
        return 'En Proceso';
      case 'completado':
        return 'Completado';
      default:
        return estado;
    }
  }

  String get estadoColor {
    switch (estado) {
      case 'creado':
        return '#6B7280'; // Gris
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
      // Estados antiguos para compatibilidad
      case 'en_proceso':
        return '#8B5CF6'; // Púrpura
      case 'completado':
        return '#10B981'; // Verde
      default:
        return '#6B7280';
    }
  }
}

class ServicioHistorial {
  final int id;
  final DateTime fecha;
  final String estado;
  final String tallerNombre;
  final String? diagnosticoDescripcion;

  ServicioHistorial({
    required this.id,
    required this.fecha,
    required this.estado,
    required this.tallerNombre,
    this.diagnosticoDescripcion,
  });

  factory ServicioHistorial.fromJson(Map<String, dynamic> json) {
    return ServicioHistorial(
      id: json['id'],
      fecha: DateTime.parse(json['fecha']),
      estado: json['estado'],
      tallerNombre: json['taller_nombre'],
      diagnosticoDescripcion: json['diagnostico_descripcion'],
    );
  }

  String get estadoTexto {
    switch (estado) {
      case 'completado':
      case 'finalizado':
        return 'Finalizado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return estado;
    }
  }
}
