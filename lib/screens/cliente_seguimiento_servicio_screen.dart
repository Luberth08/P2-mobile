import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../services/cliente_api.dart';
import '../services/session.dart';
import 'package:intl/intl.dart';

class ClienteSeguimientoServicioScreen extends StatefulWidget {
  const ClienteSeguimientoServicioScreen({Key? key}) : super(key: key);

  @override
  State<ClienteSeguimientoServicioScreen> createState() =>
      _ClienteSeguimientoServicioScreenState();
}

class _ClienteSeguimientoServicioScreenState
    extends State<ClienteSeguimientoServicioScreen> {
  ServicioSeguimientoCliente? _servicio;
  bool _cargando = true;
  String? _error;
  Timer? _timer;
  
  // Mapa
  final MapController _mapController = MapController();
  TecnicoUbicacion? _tecnicoSeleccionado;
  RutaTecnicoCliente? _ruta;
  bool _cargandoRuta = false;
  
  // Ubicación del cliente
  LatLng? _ubicacionCliente;

  @override
  void initState() {
    super.initState();
    _cargarServicio();
    // Actualizar cada 30 segundos
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _cargarServicio(silencioso: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargarServicio({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final token = await Session.getToken();
      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final servicio = await ClienteApi.obtenerServicioActual(token);

      if (mounted) {
        setState(() {
          _servicio = servicio;
          _cargando = false;
          
          // Parsear ubicación del cliente
          if (servicio?.ubicacionCliente != null) {
            final coords = servicio!.ubicacionCliente!.split(',');
            _ubicacionCliente = LatLng(
              double.parse(coords[0]),
              double.parse(coords[1]),
            );
          }
          
          // Si hay un técnico seleccionado, actualizar su ruta
          if (_tecnicoSeleccionado != null && servicio != null) {
            final tecnicoActualizado = servicio.tecnicos.firstWhere(
              (t) => t.idEmpleado == _tecnicoSeleccionado!.idEmpleado,
              orElse: () => _tecnicoSeleccionado!,
            );
            if (tecnicoActualizado.tieneUbicacion) {
              _seleccionarTecnico(tecnicoActualizado);
            }
          }
        });
      }
    } catch (e) {
      if (mounted && !silencioso) {
        setState(() {
          _error = e.toString();
          _cargando = false;
        });
      }
    }
  }

  Future<void> _seleccionarTecnico(TecnicoUbicacion tecnico) async {
    if (!tecnico.tieneUbicacion || _servicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este técnico no tiene ubicación disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _tecnicoSeleccionado = tecnico;
      _cargandoRuta = true;
    });

    try {
      final token = await Session.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      final ruta = await ClienteApi.obtenerRutaTecnico(
        token,
        _servicio!.id,
        tecnico.idEmpleado,
      );

      if (mounted) {
        setState(() {
          _ruta = ruta;
          _cargandoRuta = false;
        });

        // Centrar mapa en la ruta
        if (_ubicacionCliente != null && tecnico.latitud != null) {
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds(
                LatLng(tecnico.latitud!, tecnico.longitud!),
                _ubicacionCliente!,
              ),
              padding: const EdgeInsets.all(50),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargandoRuta = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar ruta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento del Servicio'),
        backgroundColor: Colors.blue,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarServicio,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _servicio == null
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No tienes servicios en progreso',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    )
                  : _buildContenido(),
    );
  }

  Widget _buildContenido() {
    return Column(
      children: [
        // Información del servicio
        _buildInfoServicio(),
        
        // Selector de técnicos
        _buildSelectorTecnicos(),
        
        // Mapa
        Expanded(
          child: _buildMapa(),
        ),
        
        // Historial de estados
        _buildHistorialEstados(),
      ],
    );
  }

  Widget _buildInfoServicio() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getEstadoIcon(_servicio!.estado),
                color: _getEstadoColor(_servicio!.estado),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _servicio!.estadoDescripcion,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Servicio #${_servicio!.id}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.business, 'Taller', _servicio!.taller.nombre),
          if (_servicio!.taller.telefono != null)
            _buildInfoRow(Icons.phone, 'Teléfono', _servicio!.taller.telefono!),
          if (_servicio!.diagnosticoDescripcion != null)
            _buildInfoRow(
              Icons.description,
              'Diagnóstico',
              _servicio!.diagnosticoDescripcion!,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorTecnicos() {
    if (_servicio!.tecnicos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Técnicos Asignados',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _servicio!.tecnicos.length,
              itemBuilder: (context, index) {
                final tecnico = _servicio!.tecnicos[index];
                final seleccionado = _tecnicoSeleccionado?.idEmpleado == tecnico.idEmpleado;
                
                return GestureDetector(
                  onTap: () => _seleccionarTecnico(tecnico),
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: seleccionado ? Colors.blue : Colors.white,
                      border: Border.all(
                        color: seleccionado ? Colors.blue : Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: seleccionado ? Colors.white : Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                tecnico.nombreCompleto,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: seleccionado ? Colors.white : Colors.black,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              tecnico.tieneUbicacion
                                  ? Icons.location_on
                                  : Icons.location_off,
                              color: seleccionado
                                  ? Colors.white70
                                  : (tecnico.tieneUbicacion ? Colors.green : Colors.grey),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                tecnico.tieneUbicacion
                                    ? 'Ubicación disponible'
                                    : 'Sin ubicación',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: seleccionado ? Colors.white70 : Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapa() {
    if (_ubicacionCliente == null) {
      return const Center(
        child: Text('Ubicación del cliente no disponible'),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _ubicacionCliente!,
            initialZoom: 14.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
            
            // Ruta
            if (_ruta != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _ruta!.ruta
                        .map((coord) => LatLng(coord[1], coord[0]))
                        .toList(),
                    strokeWidth: 4.0,
                    color: Colors.blue,
                  ),
                ],
              ),
            
            // Marcadores
            MarkerLayer(
              markers: [
                // Marcador del cliente
                Marker(
                  point: _ubicacionCliente!,
                  width: 80,
                  height: 80,
                  child: const Column(
                    children: [
                      Icon(
                        Icons.person_pin_circle,
                        color: Colors.green,
                        size: 40,
                      ),
                      Text(
                        'Tú',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Marcador del técnico seleccionado
                if (_tecnicoSeleccionado != null &&
                    _tecnicoSeleccionado!.tieneUbicacion)
                  Marker(
                    point: LatLng(
                      _tecnicoSeleccionado!.latitud!,
                      _tecnicoSeleccionado!.longitud!,
                    ),
                    width: 80,
                    height: 80,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.engineering,
                          color: Colors.blue,
                          size: 40,
                        ),
                        Text(
                          _tecnicoSeleccionado!.nombreCompleto.split(' ')[0],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            backgroundColor: Colors.white,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        
        // Indicador de carga de ruta
        if (_cargandoRuta)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        
        // Información de la ruta
        if (_ruta != null && _ruta!.distanciaMetros != null)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.route, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    '${(_ruta!.distanciaMetros! / 1000).toStringAsFixed(1)} km',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    '${(_ruta!.duracionSegundos! / 60).toStringAsFixed(0)} min',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHistorialEstados() {
    if (_servicio!.historialEstados.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historial de Estados',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _servicio!.historialEstados.length,
              itemBuilder: (context, index) {
                final estado = _servicio!.historialEstados[index];
                final isLast = index == _servicio!.historialEstados.length - 1;
                
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Icon(
                          _getEstadoIcon(estado.estado),
                          color: _getEstadoColor(estado.estado),
                          size: 24,
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 40,
                            color: Colors.grey.shade300,
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            estado.estadoDescripcion,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(estado.tiempo),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (!isLast) const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado) {
      case 'creado':
        return Icons.add_circle_outline;
      case 'tecnico_asignado':
        return Icons.person_add;
      case 'en_camino':
        return Icons.directions_car;
      case 'en_lugar':
        return Icons.location_on;
      case 'en_atencion':
        return Icons.build;
      case 'finalizado':
        return Icons.check_circle;
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'creado':
        return Colors.blue;
      case 'tecnico_asignado':
        return Colors.indigo;
      case 'en_camino':
        return Colors.orange;
      case 'en_lugar':
        return Colors.purple;
      case 'en_atencion':
        return Colors.amber;
      case 'finalizado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
