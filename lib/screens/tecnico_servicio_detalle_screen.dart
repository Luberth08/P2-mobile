import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../models/tecnico_servicio.dart';
import '../services/session.dart';
import '../services/tecnico_api.dart';

class TecnicoServicioDetalleScreen extends StatefulWidget {
  final ServicioTecnico servicio;
  final Position? ubicacionActual;
  final bool soloLectura; // Modo solo lectura para historial

  const TecnicoServicioDetalleScreen({
    Key? key,
    required this.servicio,
    this.ubicacionActual,
    this.soloLectura = false, // Por defecto false (modo normal)
  }) : super(key: key);

  @override
  State<TecnicoServicioDetalleScreen> createState() => _TecnicoServicioDetalleScreenState();
}

class _TecnicoServicioDetalleScreenState extends State<TecnicoServicioDetalleScreen> {
  final MapController _mapController = MapController();
  Position? _ubicacionTecnico;
  Timer? _ubicacionTimer;
  bool _actualizandoEstado = false;
  double? _distanciaActual;
  bool _enProximidad = false;
  bool _dialogoProximidadMostrado = false; // Evitar mostrar múltiples veces
  List<LatLng> _rutaPuntos = []; // Puntos de la ruta óptima
  double? _distanciaRuta; // Distancia de la ruta en metros
  double? _duracionRuta; // Duración estimada en segundos
  bool _cargandoRuta = false;
  
  // Configuración de proximidad (metros)
  static const double _distanciaProximidad = 100.0; // 100 metros

  bool _inicializado = false;

  @override
  void initState() {
    super.initState();
    _ubicacionTecnico = widget.ubicacionActual;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Inicializar solo una vez
    if (!_inicializado) {
      _inicializado = true;
      
      // Solo iniciar seguimiento si NO es modo solo lectura
      if (!widget.soloLectura) {
        _iniciarSeguimientoUbicacion();
      }
      
      _calcularDistancia();
      
      // Obtener ruta inicial si hay ubicación
      if (_ubicacionTecnico != null) {
        _obtenerRutaOptima();
      }
    }
  }

  @override
  void dispose() {
    _ubicacionTimer?.cancel();
    super.dispose();
  }

  void _iniciarSeguimientoUbicacion() {
    // Actualizar ubicación cada 10 segundos
    _ubicacionTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _obtenerUbicacionActual();
    });
  }

  Future<void> _obtenerUbicacionActual() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _ubicacionTecnico = position;
      });
      
      _calcularDistancia();
      _obtenerRutaOptima(); // Obtener ruta cada vez que se actualiza la ubicación
      _enviarUbicacionAlServidor();
      
    } catch (e) {
      print('Error obteniendo ubicación: $e');
    }
  }

  void _calcularDistancia() {
    if (_ubicacionTecnico != null) {
      final distancia = Geolocator.distanceBetween(
        _ubicacionTecnico!.latitude,
        _ubicacionTecnico!.longitude,
        widget.servicio.cliente.ubicacionLat,
        widget.servicio.cliente.ubicacionLon,
      );
      
      setState(() {
        _distanciaActual = distancia;
        _enProximidad = distancia <= _distanciaProximidad;
      });
      
      // Auto-actualizar estado si está en proximidad y el estado lo permite
      _verificarAutoActualizacion();
    }
  }

  Future<void> _obtenerRutaOptima() async {
    if (_ubicacionTecnico == null || _cargandoRuta) return;
    
    setState(() => _cargandoRuta = true);
    
    try {
      // Usar OSRM (Open Source Routing Machine) - servicio gratuito
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${_ubicacionTecnico!.longitude},${_ubicacionTecnico!.latitude};'
        '${widget.servicio.cliente.ubicacionLon},${widget.servicio.cliente.ubicacionLat}'
        '?overview=full&geometries=geojson'
      );
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('La solicitud de ruta tardó demasiado');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry']['coordinates'] as List;
          
          // Convertir coordenadas [lon, lat] a LatLng
          final puntos = geometry.map((coord) {
            return LatLng(coord[1] as double, coord[0] as double);
          }).toList();
          
          setState(() {
            _rutaPuntos = puntos;
            _distanciaRuta = route['distance'] as double?; // en metros
            _duracionRuta = route['duration'] as double?; // en segundos
            _cargandoRuta = false;
          });
        } else {
          throw Exception('No se encontró una ruta válida');
        }
      } else {
        throw Exception('Error al obtener ruta: ${response.statusCode}');
      }
    } catch (e) {
      print('Error obteniendo ruta: $e');
      setState(() {
        _cargandoRuta = false;
        // Si falla, usar línea recta como fallback
        _rutaPuntos = [
          LatLng(_ubicacionTecnico!.latitude, _ubicacionTecnico!.longitude),
          LatLng(widget.servicio.cliente.ubicacionLat, widget.servicio.cliente.ubicacionLon),
        ];
      });
    }
  }

  void _verificarAutoActualizacion() {
    if (!_enProximidad || _actualizandoEstado || _dialogoProximidadMostrado) return;
    
    // Auto-actualizar a "en_lugar" si está en camino y llega al lugar
    if (widget.servicio.estado == 'en_camino') {
      // Marcar que ya se mostró el diálogo
      _dialogoProximidadMostrado = true;
      
      // Mostrar diálogo después del build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_actualizandoEstado) {
          _mostrarDialogoAutoActualizacion(
            'Has llegado al lugar del cliente',
            EstadoServicioTecnico.enLugar,
          );
        }
      });
    }
  }

  void _mostrarDialogoAutoActualizacion(String mensaje, EstadoServicioTecnico nuevoEstado) {
    showDialog(
      context: context,
      barrierDismissible: false, // No cerrar al tocar fuera
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Actualización Automática'),
        content: Text('$mensaje. ¿Actualizar el estado del servicio?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Resetear el flag para permitir mostrar el diálogo nuevamente si es necesario
              setState(() {
                _dialogoProximidadMostrado = false;
              });
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _actualizarEstado(nuevoEstado);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF932D30),
              foregroundColor: Colors.white,
            ),
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  Future<void> _enviarUbicacionAlServidor() async {
    if (_ubicacionTecnico == null) return;
    
    // Solo enviar ubicación si el servicio está activo
    if (!['tecnico_asignado', 'en_camino', 'en_lugar', 'en_atencion']
        .contains(widget.servicio.estado)) {
      return;
    }
    
    try {
      final token = await Session.getToken();
      if (token != null) {
        await TecnicoApi.actualizarUbicacionTecnico(
          token,
          widget.servicio.id,
          _ubicacionTecnico!.latitude,
          _ubicacionTecnico!.longitude,
        );
        print('✅ Ubicación enviada al backend');
      }
    } catch (e) {
      print('⚠️ Error enviando ubicación: $e');
      // No mostramos error al usuario, es un proceso en segundo plano
    }
  }

  Future<void> _actualizarEstado(EstadoServicioTecnico nuevoEstado) async {
    if (_actualizandoEstado) return; // Prevenir múltiples llamadas
    
    setState(() => _actualizandoEstado = true);
    
    try {
      final token = await Session.getToken();
      if (token != null) {
        await TecnicoApi.actualizarEstadoServicio(
          token,
          widget.servicio.id,
          nuevoEstado,
          latitud: _ubicacionTecnico?.latitude,
          longitud: _ubicacionTecnico?.longitude,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Estado actualizado a: ${nuevoEstado.descripcion}'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Volver a la pantalla anterior para refrescar
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar estado: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // Resetear el flag si hubo error para permitir reintentar
        setState(() {
          _actualizandoEstado = false;
          _dialogoProximidadMostrado = false;
        });
      }
    }
  }

  Future<void> _llamarCliente() async {
    if (widget.servicio.cliente.telefono == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El cliente no tiene teléfono registrado')),
      );
      return;
    }

    final uri = Uri.parse('tel:${widget.servicio.cliente.telefono}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se puede realizar la llamada')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Servicio #${widget.servicio.id}'),
        backgroundColor: const Color(0xFF932D30),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: _llamarCliente,
            tooltip: 'Llamar Cliente',
          ),
        ],
      ),
      body: Column(
        children: [
          // Información del servicio
          _buildInfoHeader(),
          
          // Mapa
          Expanded(
            flex: 3,
            child: _buildMapa(),
          ),
          
          // Checklist y controles
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: _buildControles(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(int.parse(widget.servicio.estadoColor.replaceFirst('#', '0xFF'))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                widget.servicio.estadoIcono,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.servicio.estadoDescripcion,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.servicio.cliente.nombre,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (_distanciaActual != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _enProximidad ? Colors.green : Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _enProximidad ? Icons.location_on : Icons.location_off,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(_distanciaActual! / 1000).toStringAsFixed(1)} km',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_enProximidad)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'En proximidad del cliente',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapa() {
    if (_ubicacionTecnico == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Obteniendo ubicación...'),
          ],
        ),
      );
    }

    final tecnicoLatLng = LatLng(_ubicacionTecnico!.latitude, _ubicacionTecnico!.longitude);
    final clienteLatLng = LatLng(widget.servicio.cliente.ubicacionLat, widget.servicio.cliente.ubicacionLon);
    
    // Calcular bounds para mostrar ambos puntos (o toda la ruta si existe)
    final puntosParaBounds = _rutaPuntos.isNotEmpty ? _rutaPuntos : [tecnicoLatLng, clienteLatLng];
    final bounds = LatLngBounds.fromPoints(puntosParaBounds);
    
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            bounds: bounds,
            boundsOptions: const FitBoundsOptions(
              padding: EdgeInsets.all(50),
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.mobile_repo',
            ),
            
            // Línea de ruta óptima
            if (_rutaPuntos.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _rutaPuntos,
                    strokeWidth: 5.0,
                    color: const Color(0xFF932D30),
                    borderStrokeWidth: 2.0,
                    borderColor: Colors.white,
                  ),
                ],
              ),
            
            // Marcadores
            MarkerLayer(
              markers: [
                // Marcador del técnico
                Marker(
                  point: tecnicoLatLng,
                  width: 60,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.engineering,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                
                // Marcador del cliente
                Marker(
                  point: clienteLatLng,
                  width: 60,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF932D30),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        
        // Información de la ruta en la parte superior del mapa
        if (_distanciaRuta != null && _duracionRuta != null)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoRuta(
                    Icons.route,
                    '${(_distanciaRuta! / 1000).toStringAsFixed(1)} km',
                    'Distancia',
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey[300],
                  ),
                  _buildInfoRuta(
                    Icons.access_time,
                    '${(_duracionRuta! / 60).ceil()} min',
                    'Tiempo est.',
                  ),
                ],
              ),
            ),
          ),
        
        // Indicador de carga de ruta
        if (_cargandoRuta)
          Positioned(
            bottom: 16,
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Calculando ruta...',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRuta(IconData icono, String valor, String etiqueta) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 18, color: const Color(0xFF932D30)),
            const SizedBox(width: 6),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          etiqueta,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildControles() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          const Text(
            'Control del Servicio',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Checklist automático
          _buildChecklist(),
          
          const SizedBox(height: 16),
          
          // Botones de acción
          _buildBotonesAccion(),
        ],
      ),
    );
  }

  Widget _buildChecklist() {
    final items = [
      ChecklistItem(
        titulo: 'Técnico asignado',
        completado: ['tecnico_asignado', 'en_camino', 'en_lugar', 'en_atencion', 'finalizado'].contains(widget.servicio.estado),
        icono: Icons.assignment_ind,
      ),
      ChecklistItem(
        titulo: 'En camino al cliente',
        completado: ['en_camino', 'en_lugar', 'en_atencion', 'finalizado'].contains(widget.servicio.estado),
        icono: Icons.directions_car,
      ),
      ChecklistItem(
        titulo: 'Llegada al lugar (Auto <100m)',
        completado: ['en_lugar', 'en_atencion', 'finalizado'].contains(widget.servicio.estado) || _enProximidad,
        icono: Icons.location_on,
        automatico: true, // Siempre mostrar que es automático
      ),
      ChecklistItem(
        titulo: 'Atención en progreso',
        completado: ['en_atencion', 'finalizado'].contains(widget.servicio.estado),
        icono: Icons.build,
      ),
      ChecklistItem(
        titulo: 'Servicio finalizado',
        completado: widget.servicio.estado == 'finalizado',
        icono: Icons.check_circle,
      ),
    ];

    return Column(
      children: items.map((item) => _buildChecklistItem(item)).toList(),
    );
  }

  Widget _buildChecklistItem(ChecklistItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: item.completado ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.completado ? Colors.green : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            item.completado ? Icons.check_circle : item.icono,
            color: item.completado ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.titulo,
              style: TextStyle(
                color: item.completado ? Colors.green[700] : Colors.grey[700],
                fontWeight: item.completado ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
          if (item.automatico)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.gps_fixed, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'GPS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBotonesAccion() {
    // Si es modo solo lectura, no mostrar botones de acción
    if (widget.soloLectura) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.info, color: Colors.grey),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Servicio histórico - Solo lectura',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    final siguientesEstados = widget.servicio.siguientesEstados;
    
    if (siguientesEstados.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text(
              'Servicio completado',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: siguientesEstados.map((estadoStr) {
        final estado = EstadoServicioTecnico.values.firstWhere(
          (e) => e.value == estadoStr,
        );
        
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          child: ElevatedButton.icon(
            onPressed: _actualizandoEstado ? null : () => _actualizarEstado(estado),
            icon: _actualizandoEstado 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_getEstadoIcon(estado)),
            label: Text(_actualizandoEstado ? 'Actualizando...' : estado.descripcion),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF932D30),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getEstadoIcon(EstadoServicioTecnico estado) {
    switch (estado) {
      case EstadoServicioTecnico.enCamino:
        return Icons.directions_car;
      case EstadoServicioTecnico.enLugar:
        return Icons.location_on;
      case EstadoServicioTecnico.enAtencion:
        return Icons.build;
      case EstadoServicioTecnico.finalizado:
        return Icons.check_circle;
      default:
        return Icons.arrow_forward;
    }
  }
}

class ChecklistItem {
  final String titulo;
  final bool completado;
  final IconData icono;
  final bool automatico;

  ChecklistItem({
    required this.titulo,
    required this.completado,
    required this.icono,
    this.automatico = false,
  });
}