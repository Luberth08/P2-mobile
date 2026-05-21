import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/servicio.dart';
import '../services/cliente_api.dart';
import '../services/session.dart';

class ServicioDetalleScreen extends StatefulWidget {
  final ServicioCliente servicio;

  const ServicioDetalleScreen({
    Key? key,
    required this.servicio,
  }) : super(key: key);

  @override
  State<ServicioDetalleScreen> createState() => _ServicioDetalleScreenState();
}

class _ServicioDetalleScreenState extends State<ServicioDetalleScreen> {
  ServicioSeguimientoCliente? _seguimiento;
  bool _cargando = true;
  Timer? _timer;
  
  // Mapa
  final MapController _mapController = MapController();
  TecnicoUbicacion? _tecnicoSeleccionado;
  RutaTecnicoCliente? _ruta;
  bool _cargandoRuta = false;
  LatLng? _ubicacionCliente;

  @override
  void initState() {
    super.initState();
    
    // Intentar obtener ubicación del cliente desde el servicio original
    if (widget.servicio.ubicacionCliente != null) {
      try {
        final coords = widget.servicio.ubicacionCliente!.split(',');
        _ubicacionCliente = LatLng(
          double.parse(coords[0]),
          double.parse(coords[1]),
        );
        print('✅ Ubicación inicial del servicio: $_ubicacionCliente');
      } catch (e) {
        print('❌ Error parseando ubicación inicial: $e');
      }
    }
    
    _cargarSeguimiento();
    // Actualizar cada 30 segundos
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _cargarSeguimiento(silencioso: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargarSeguimiento({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() => _cargando = true);
    }

    try {
      final token = await Session.getToken();
      if (token == null) {
        print('❌ No hay token');
        return;
      }

      print('🔍 Cargando seguimiento para servicio ${widget.servicio.id}');
      final seguimiento = await ClienteApi.obtenerServicioActual(token);
      print('📦 Seguimiento recibido: ${seguimiento != null ? "SÍ" : "NO"}');

      if (seguimiento != null) {
        print('📍 Ubicación cliente: ${seguimiento.ubicacionCliente}');
        print('👥 Técnicos: ${seguimiento.tecnicos.length}');
        print('📜 Historial: ${seguimiento.historialEstados.length}');
      }

      if (mounted && seguimiento != null && seguimiento.id == widget.servicio.id) {
        setState(() {
          _seguimiento = seguimiento;
          _cargando = false;
          
          // Parsear ubicación del cliente
          if (seguimiento.ubicacionCliente != null) {
            try {
              final coords = seguimiento.ubicacionCliente!.split(',');
              _ubicacionCliente = LatLng(
                double.parse(coords[0]),
                double.parse(coords[1]),
              );
              print('✅ Ubicación cliente parseada: $_ubicacionCliente');
            } catch (e) {
              print('❌ Error parseando ubicación: $e');
            }
          } else {
            print('⚠️ No hay ubicación del cliente en el seguimiento');
          }
          
          // Si hay un técnico seleccionado, actualizar su ruta
          if (_tecnicoSeleccionado != null) {
            final tecnicoActualizado = seguimiento.tecnicos.firstWhere(
              (t) => t.idEmpleado == _tecnicoSeleccionado!.idEmpleado,
              orElse: () => _tecnicoSeleccionado!,
            );
            if (tecnicoActualizado.tieneUbicacion) {
              _seleccionarTecnico(tecnicoActualizado);
            }
          }
        });
      } else if (mounted) {
        print('⚠️ Seguimiento no coincide o es null');
        setState(() => _cargando = false);
      }
    } catch (e) {
      print('❌ Error cargando seguimiento: $e');
      if (mounted && !silencioso) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _seleccionarTecnico(TecnicoUbicacion tecnico) async {
    if (!tecnico.tieneUbicacion || _seguimiento == null) {
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
        _seguimiento!.id,
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
        setState(() => _cargandoRuta = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar ruta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getEstadoColor() {
    return Color(int.parse(widget.servicio.estadoColor.replaceFirst('#', '0xFF')));
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
      case 'en_proceso':
        return Icons.engineering;
      case 'completado':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  Color _getEstadoColorByName(String estado) {
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

  Future<void> _llamarTaller(BuildContext context) async {
    if (widget.servicio.taller.telefono == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El taller no tiene teléfono registrado')),
      );
      return;
    }

    final uri = Uri.parse('tel:${widget.servicio.taller.telefono}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se puede realizar la llamada')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF932D30),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Detalle del Servicio',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _cargarSeguimiento(),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con estado
                  _buildHeader(),
                  
                  // Información del taller
                  _buildTallerSection(context),
                  
                  // Selector de técnicos (mostrar si hay técnicos asignados)
                  if (widget.servicio.tecnicosAsignados.isNotEmpty)
                    _buildSelectorTecnicos(),
                  
                  // Mapa con seguimiento (siempre mostrar)
                  _buildMapaConSeguimiento(),
                  
                  // Historial de estados
                  if (_seguimiento != null && _seguimiento!.historialEstados.isNotEmpty)
                    _buildHistorialEstados(),
                  
                  // Diagnóstico
                  if (widget.servicio.diagnostico != null)
                    _buildDiagnosticoSection(),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final estado = _seguimiento?.estadoDescripcion ?? widget.servicio.estadoTexto;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getEstadoColor(),
            _getEstadoColor().withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getEstadoIcon(widget.servicio.estado),
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            estado.toUpperCase(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Servicio #${widget.servicio.id}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatFecha(widget.servicio.fecha),
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTallerSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF932D30).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.store,
                  color: Color(0xFF932D30),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'TALLER',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF52341A),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.servicio.taller.puntos.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.servicio.taller.nombre,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
          if (widget.servicio.taller.direccion != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 18,
                  color: Color(0xFF52341A),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.servicio.taller.direccion!,
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF52341A).withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (widget.servicio.taller.telefono != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _llamarTaller(context),
              child: Row(
                children: [
                  const Icon(
                    Icons.phone,
                    size: 18,
                    color: Color(0xFF932D30),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.servicio.taller.telefono!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF932D30),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectorTecnicos() {
    // Usar técnicos del seguimiento si están disponibles, sino usar los del servicio original
    final tecnicos = _seguimiento?.tecnicos ?? [];
    
    // Si no hay seguimiento, crear lista de técnicos desde el servicio original
    final tecnicosParaMostrar = tecnicos.isEmpty
        ? widget.servicio.tecnicosAsignados.map((t) => TecnicoUbicacion(
            idEmpleado: t.idEmpleado,
            nombreCompleto: t.nombreCompleto,
            latitud: null,
            longitud: null,
            timestamp: null,
            tieneUbicacion: false,
          )).toList()
        : tecnicos;
    
    if (tecnicosParaMostrar.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'TÉCNICOS ASIGNADOS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF52341A),
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (_seguimiento == null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sync, size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Cargando ubicaciones...',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tecnicosParaMostrar.length,
              itemBuilder: (context, index) {
                final tecnico = tecnicosParaMostrar[index];
                final seleccionado = _tecnicoSeleccionado?.idEmpleado == tecnico.idEmpleado;
                
                return GestureDetector(
                  onTap: () {
                    if (_seguimiento != null && tecnicos.isNotEmpty) {
                      _seleccionarTecnico(tecnico);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Esperando ubicaciones de los técnicos...'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: seleccionado ? const Color(0xFF932D30) : Colors.white,
                      border: Border.all(
                        color: seleccionado ? const Color(0xFF932D30) : Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: seleccionado
                          ? [
                              BoxShadow(
                                color: const Color(0xFF932D30).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: seleccionado ? Colors.white : const Color(0xFF932D30),
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
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
                                  fontSize: 11,
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

  Widget _buildMapaConSeguimiento() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 350,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _ubicacionCliente == null
            ? _buildMapaPlaceholder()
            : _buildMapaConDatos(),
      ),
    );
  }

  Widget _buildMapaPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Ubicación no disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'La ubicación del servicio no está disponible en este momento',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _cargarSeguimiento(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF932D30),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapaConDatos() {
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
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.tallermovil',
              additionalOptions: const {
                'attribution': '© OpenStreetMap contributors',
              },
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
                    color: const Color(0xFF932D30),
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
                          color: Color(0xFF932D30),
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
                  const Icon(Icons.route, color: Color(0xFF932D30)),
                  const SizedBox(width: 8),
                  Text(
                    '${(_ruta!.distanciaMetros! / 1000).toStringAsFixed(1)} km',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, color: Color(0xFF932D30)),
                  const SizedBox(width: 8),
                  Text(
                    '${(_ruta!.duracionSegundos! / 60).toStringAsFixed(0)} min',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        
        // Mensaje si no hay técnico seleccionado
        if (_tecnicoSeleccionado == null && _seguimiento != null && _seguimiento!.tecnicos.isNotEmpty)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF932D30),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selecciona un técnico arriba para ver su ubicación',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHistorialEstados() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF932D30).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.timeline,
                  color: Color(0xFF932D30),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'HISTORIAL DE ESTADOS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF52341A),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._seguimiento!.historialEstados.asMap().entries.map((entry) {
            final index = entry.key;
            final estado = entry.value;
            final isLast = index == _seguimiento!.historialEstados.length - 1;
            
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Icon(
                      _getEstadoIcon(estado.estado),
                      color: _getEstadoColorByName(estado.estado),
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
          }),
        ],
      ),
    );
  }

  Widget _buildDiagnosticoSection() {
    final diagnostico = widget.servicio.diagnostico!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF932D30).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medical_services,
                  color: Color(0xFF932D30),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'DIAGNÓSTICO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF52341A),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (diagnostico.descripcion != null) ...[
            Text(
              diagnostico.descripcion!,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF2C2C2C),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              const Text(
                'Nivel de confianza:',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF52341A),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(diagnostico.nivelConfianza * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF932D30),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    
    return '${fecha.day} ${months[fecha.month - 1]} ${fecha.year}, ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }
}
