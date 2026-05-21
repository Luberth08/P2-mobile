import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/session.dart';
import '../services/tecnico_api.dart';
import '../models/tecnico_servicio.dart';
import 'tecnico_servicio_detalle_screen.dart';

class TecnicoTab extends StatefulWidget {
  const TecnicoTab({Key? key}) : super(key: key);

  @override
  State<TecnicoTab> createState() => _TecnicoTabState();
}

class _TecnicoTabState extends State<TecnicoTab> with SingleTickerProviderStateMixin {
  List<TallerTecnicoInfo> _talleres = [];
  List<ServicioTecnico> _serviciosActivos = [];
  List<ServicioTecnico> _serviciosHistorial = [];
  bool _loadingTalleres = true;
  bool _loadingServicios = false;
  int? _tallerSeleccionado;
  Timer? _refreshTimer;
  Position? _ubicacionActual;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTalleres();
    _obtenerUbicacion();
    
    // Refresh automático cada 30 segundos (solo para servicios activos)
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && _tallerSeleccionado != null && _tabController.index == 0) {
        _loadServiciosActivos(_tallerSeleccionado!);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _obtenerUbicacion() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      _ubicacionActual = await Geolocator.getCurrentPosition();
    } catch (e) {
      print('Error obteniendo ubicación: $e');
    }
  }

  Future<void> _loadTalleres() async {
    setState(() => _loadingTalleres = true);
    try {
      final token = await Session.getToken();
      if (token != null) {
        final talleres = await TecnicoApi.obtenerTalleres(token);
        setState(() {
          _talleres = talleres;
          _loadingTalleres = false;
        });
      }
    } catch (e) {
      setState(() => _loadingTalleres = false);
      _showError('Error al cargar talleres: $e');
    }
  }

  Future<void> _loadServiciosActivos(int tallerId) async {
    setState(() => _loadingServicios = true);
    try {
      final token = await Session.getToken();
      if (token != null) {
        final servicios = await TecnicoApi.obtenerServiciosAsignados(token, tallerId);
        setState(() {
          _serviciosActivos = servicios;
          _loadingServicios = false;
        });
      }
    } catch (e) {
      setState(() => _loadingServicios = false);
      _showError('Error al cargar servicios activos: $e');
    }
  }

  Future<void> _loadServiciosHistorial(int tallerId) async {
    setState(() => _loadingServicios = true);
    try {
      final token = await Session.getToken();
      if (token != null) {
        final servicios = await TecnicoApi.obtenerHistorialServicios(token, tallerId);
        setState(() {
          _serviciosHistorial = servicios;
          _loadingServicios = false;
        });
      }
    } catch (e) {
      setState(() => _loadingServicios = false);
      _showError('Error al cargar historial: $e');
    }
  }

  Future<void> _loadServicios(int tallerId) async {
    // Cargar ambos: activos e historial
    await Future.wait([
      _loadServiciosActivos(tallerId),
      _loadServiciosHistorial(tallerId),
    ]);
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios Técnico'),
        backgroundColor: const Color(0xFF932D30),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadTalleres();
              if (_tallerSeleccionado != null) {
                if (_tabController.index == 0) {
                  _loadServiciosActivos(_tallerSeleccionado!);
                } else {
                  _loadServiciosHistorial(_tallerSeleccionado!);
                }
              }
            },
          ),
        ],
        bottom: _tallerSeleccionado != null
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                onTap: (index) {
                  if (_tallerSeleccionado != null) {
                    if (index == 0) {
                      _loadServiciosActivos(_tallerSeleccionado!);
                    } else {
                      _loadServiciosHistorial(_tallerSeleccionado!);
                    }
                  }
                },
                tabs: const [
                  Tab(
                    icon: Icon(Icons.assignment),
                    text: 'Activos',
                  ),
                  Tab(
                    icon: Icon(Icons.history),
                    text: 'Historial',
                  ),
                ],
              )
            : null,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F2EB), Color(0xFFE8E3DA)],
          ),
        ),
        child: Column(
          children: [
            // Selector de Taller
            _buildTallerSelector(),
            
            // Contenido con pestañas
            Expanded(
              child: _tallerSeleccionado == null
                  ? _buildSeleccionarTaller()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildListaServicios(_serviciosActivos, 'activos'),
                        _buildListaServicios(_serviciosHistorial, 'historial'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTallerSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _loadingTalleres
          ? const Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Cargando talleres...'),
              ],
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                hint: const Text('Seleccionar Taller'),
                value: _tallerSeleccionado,
                items: _talleres.map((taller) {
                  return DropdownMenuItem<int>(
                    value: taller.id,
                    child: Row(
                      children: [
                        const Icon(Icons.store, color: Color(0xFF932D30)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                taller.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${taller.serviciosActivos} servicios activos',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _tallerSeleccionado = value;
                  });
                  if (value != null) {
                    _loadServicios(value);
                  }
                },
              ),
            ),
    );
  }

  Widget _buildSeleccionarTaller() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.store,
              size: 64,
              color: Color(0xFF932D30),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Selecciona un Taller',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Elige un taller para ver tus servicios asignados',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF52341A).withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListaServicios(List<ServicioTecnico> servicios, String tipo) {
    if (_loadingServicios) {
      return const Center(child: CircularProgressIndicator());
    }

    if (servicios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                tipo == 'activos' ? Icons.assignment : Icons.history,
                size: 64,
                color: const Color(0xFF932D30),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              tipo == 'activos' ? 'Sin Servicios Activos' : 'Sin Historial',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tipo == 'activos'
                  ? 'No tienes servicios asignados en este taller'
                  : 'No hay servicios finalizados en este taller',
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFF52341A).withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => tipo == 'activos'
          ? _loadServiciosActivos(_tallerSeleccionado!)
          : _loadServiciosHistorial(_tallerSeleccionado!),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: servicios.length,
        itemBuilder: (context, index) {
          final servicio = servicios[index];
          return _buildServicioCard(servicio, tipo == 'historial');
        },
      ),
    );
  }

  Widget _buildServicioCard(ServicioTecnico servicio, [bool esHistorial = false]) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // Permitir ver detalle tanto en activos como en historial
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TecnicoServicioDetalleScreen(
                servicio: servicio,
                ubicacionActual: _ubicacionActual,
                soloLectura: esHistorial, // Modo solo lectura para historial
              ),
            ),
          ).then((_) {
            // Refresh después de volver del detalle (solo para activos)
            if (_tallerSeleccionado != null && !esHistorial) {
              _loadServiciosActivos(_tallerSeleccionado!);
            }
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con estado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(int.parse(servicio.estadoColor.replaceFirst('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          servicio.estadoIcono,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          servicio.estadoDescripcion,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'ID: ${servicio.id}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Información del cliente
              Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFF932D30), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          servicio.cliente.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (servicio.cliente.telefono != null)
                          Text(
                            servicio.cliente.telefono!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Fecha
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF932D30), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${servicio.fecha.day}/${servicio.fecha.month}/${servicio.fecha.year} ${servicio.fecha.hour}:${servicio.fecha.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Distancia si está disponible (solo para activos)
              if (!esHistorial && servicio.distanciaClienteKm != null)
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF932D30), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${servicio.distanciaClienteKm!.toStringAsFixed(1)} km de distancia',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              
              if (!esHistorial && servicio.distanciaClienteKm != null)
                const SizedBox(height: 12),
              
              // Vehículos asignados
              if (servicio.vehiculosAsignados.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.directions_car, color: Color(0xFF932D30), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        servicio.vehiculosAsignados
                            .map((v) => '${v.marca} ${v.modelo} (${v.matricula})')
                            .join(', '),
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              
              // Botón de acción (para ambos, pero con texto diferente)
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TecnicoServicioDetalleScreen(
                          servicio: servicio,
                          ubicacionActual: _ubicacionActual,
                          soloLectura: esHistorial,
                        ),
                      ),
                    ).then((_) {
                      if (_tallerSeleccionado != null && !esHistorial) {
                        _loadServiciosActivos(_tallerSeleccionado!);
                      }
                    });
                  },
                  icon: Icon(esHistorial ? Icons.info : Icons.visibility),
                  label: Text(esHistorial ? 'Ver Información' : 'Ver Detalles'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF932D30),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}