import 'dart:async';
import 'package:flutter/material.dart';
import '../services/session.dart';
import '../services/diagnostic_api.dart';
import '../services/servicio_api.dart';
import '../services/cliente_api.dart';
import '../models/servicio.dart';
import '../widgets/valoracion_dialog.dart';
import 'diagnostic_result_screen.dart';
import 'servicio_detalle_screen.dart';

class ServiciosTab extends StatefulWidget {
  const ServiciosTab({Key? key}) : super(key: key);

  @override
  State<ServiciosTab> createState() => _ServiciosTabState();
}

class _ServiciosTabState extends State<ServiciosTab> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  Timer? _refreshTimer;
  
  // Servicio actual
  ServicioCliente? _servicioActual;
  bool _loadingServicio = true;
  
  // Solicitudes pendientes
  List<Map<String, dynamic>> _solicitudes = [];
  bool _loadingSolicitudes = true;
  
  // Historial
  List<ServicioHistorial> _historial = [];
  bool _loadingHistorial = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _loadAllData();
    
    // Configurar refresh automático cada 30 segundos para servicios activos
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadServicioActual();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh when app comes back to foreground
      _loadServicioActual();
    }
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadServicioActual(),
      _loadSolicitudes(),
      _loadHistorial(),
    ]);
  }

  Future<void> _loadServicioActual() async {
    print('🚀 Iniciando _loadServicioActual()');
    setState(() => _loadingServicio = true);
    try {
      final token = await Session.getToken();
      print('🔑 Token obtenido: ${token != null ? "SÍ" : "NO"}');
      if (token != null) {
        // TEMPORAL: Debug todos los servicios
        try {
          print('🔍 DEBUG: Consultando todos los servicios primero...');
          final debug = await ServicioApi.debugTodosLosServicios(token);
          print('📊 DEBUG RESULTADO: $debug');
        } catch (e) {
          print('❌ Error en debug: $e');
        }
        
        print('📞 Llamando a ServicioApi.obtenerServicioActual()');
        final servicio = await ServicioApi.obtenerServicioActual(token);
        print('📋 Servicio recibido: ${servicio != null ? "SÍ" : "NO"}');
        setState(() {
          _servicioActual = servicio;
          _loadingServicio = false;
        });
      } else {
        print('❌ No hay token, no se puede consultar servicio');
        setState(() => _loadingServicio = false);
      }
    } catch (e) {
      setState(() => _loadingServicio = false);
      print('❌ Error al cargar servicio actual: $e');
    }
  }

  Future<void> _loadSolicitudes() async {
    setState(() => _loadingSolicitudes = true);
    try {
      final token = await Session.getToken();
      if (token != null) {
        final solicitudes = await DiagnosticApi.getMySolicitudes(token);
        setState(() {
          _solicitudes = solicitudes;
          _loadingSolicitudes = false;
        });
      }
    } catch (e) {
      setState(() => _loadingSolicitudes = false);
      print('Error al cargar solicitudes: $e');
    }
  }

  Future<void> _loadHistorial() async {
    setState(() => _loadingHistorial = true);
    try {
      final token = await Session.getToken();
      if (token != null) {
        final historial = await ServicioApi.obtenerHistorialServicios(token);
        setState(() {
          _historial = historial;
          _loadingHistorial = false;
        });
      }
    } catch (e) {
      setState(() => _loadingHistorial = false);
      print('Error al cargar historial: $e');
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'procesando':
        return Colors.blue;
      case 'diagnosticada':
        return Colors.green;
      case 'cancelada':
      case 'cancelado':
        return Colors.red;
      case 'error':
        return Colors.red;
      case 'creado':
        return const Color(0xFF3B82F6);
      case 'en_proceso':
        return const Color(0xFF8B5CF6);
      case 'completado':
      case 'finalizado':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado) {
      case 'pendiente':
        return Icons.pending;
      case 'procesando':
        return Icons.sync;
      case 'diagnosticada':
        return Icons.check_circle;
      case 'cancelada':
      case 'cancelado':
        return Icons.cancel;
      case 'error':
        return Icons.error;
      case 'creado':
        return Icons.build;
      case 'en_proceso':
        return Icons.engineering;
      case 'completado':
      case 'finalizado':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Servicios'),
        backgroundColor: const Color(0xFF932D30),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
            tooltip: 'Actualizar',
          ),
        ],
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
            // DEBUG: Mostrar información de debug
            if (_loadingServicio)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue),
                ),
                child: const Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Buscando servicio activo...'),
                  ],
                ),
              )
            else if (_servicioActual == null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'No hay servicio activo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Si un taller acaba de aceptar tu solicitud, toca el botón de actualizar.',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _loadServicioActual,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Actualizar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              )
            else
              _buildServicioActualCard(),
            
            // Tabs
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF932D30),
                unselectedLabelColor: const Color(0xFF52341A).withOpacity(0.6),
                indicatorColor: const Color(0xFF932D30),
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Solicitudes'),
                  Tab(text: 'Historial'),
                  Tab(text: 'Todos'),
                ],
              ),
            ),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSolicitudesTab(),
                  _buildHistorialTab(),
                  _buildTodosTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicioActualCard() {
    if (_servicioActual == null) return const SizedBox.shrink();
    
    final servicio = _servicioActual!;
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(int.parse(servicio.estadoColor.replaceFirst('#', '0xFF'))),
            Color(int.parse(servicio.estadoColor.replaceFirst('#', '0xFF'))).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServicioDetalleScreen(servicio: servicio),
              ),
            ).then((_) => _loadServicioActual());
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getEstadoIcon(servicio.estado),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SERVICIO EN CURSO',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            servicio.estadoTexto.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.store,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Taller',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              servicio.taller.nombre,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (servicio.tecnicosAsignados.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.engineering,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Técnicos',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                servicio.tecnicosAsignados.map((t) => t.nombreCompleto).join(', '),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSolicitudesTab() {
    if (_loadingSolicitudes) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_solicitudes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox,
        title: 'No hay solicitudes',
        subtitle: 'Tus solicitudes de diagnóstico aparecerán aquí',
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadSolicitudes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _solicitudes.length,
        itemBuilder: (context, index) {
          final solicitud = _solicitudes[index];
          return _buildSolicitudCard(solicitud);
        },
      ),
    );
  }

  Widget _buildHistorialTab() {
    if (_loadingHistorial) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_historial.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'Sin historial',
        subtitle: 'Los servicios completados aparecerán aquí',
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadHistorial,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _historial.length,
        itemBuilder: (context, index) {
          final servicio = _historial[index];
          return _buildHistorialCard(servicio);
        },
      ),
    );
  }

  Widget _buildTodosTab() {
    final allEmpty = _solicitudes.isEmpty && _historial.isEmpty;
    
    if (_loadingSolicitudes || _loadingHistorial) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (allEmpty) {
      return _buildEmptyState(
        icon: Icons.list_alt,
        title: 'Sin actividad',
        subtitle: 'Tus solicitudes y servicios aparecerán aquí',
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_solicitudes.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'SOLICITUDES PENDIENTES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF52341A),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ..._solicitudes.map((s) => _buildSolicitudCard(s)),
            const SizedBox(height: 24),
          ],
          if (_historial.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'HISTORIAL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF52341A),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ..._historial.map((s) => _buildHistorialCard(s)),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
              icon,
              size: 64,
              color: const Color(0xFF932D30),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
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

  Widget _buildSolicitudCard(Map<String, dynamic> solicitud) {
    final estado = solicitud['estado'] ?? 'desconocido';
    final descripcion = solicitud['descripcion'] ?? 'Sin descripción';
    final fechaCreacion = solicitud['fecha_creacion'] ?? '';
    final vehiculo = solicitud['vehiculo'];
    final diagnostico = solicitud['diagnostico'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiagnosticResultScreen(
                solicitudId: solicitud['id'],
              ),
            ),
          ).then((_) => _loadSolicitudes());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getEstadoIcon(estado),
                    color: _getEstadoColor(estado),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      estado.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getEstadoColor(estado),
                      ),
                    ),
                  ),
                  if (fechaCreacion.isNotEmpty)
                    Text(
                      _formatFecha(fechaCreacion),
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF52341A).withOpacity(0.6),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                descripcion,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2C2C2C),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (vehiculo != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.directions_car,
                      size: 16,
                      color: Color(0xFF52341A),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${vehiculo['matricula']} - ${vehiculo['marca']} ${vehiculo['modelo']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF52341A).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
              if (diagnostico != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF932D30).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Color(0xFF932D30),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Diagnóstico disponible',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF932D30),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistorialCard(ServicioHistorial servicio) {
    final esCompletado = servicio.estado == 'completado' || servicio.estado == 'finalizado';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getEstadoIcon(servicio.estado),
                  color: _getEstadoColor(servicio.estado),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    servicio.estadoTexto.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getEstadoColor(servicio.estado),
                    ),
                  ),
                ),
                Text(
                  _formatFecha(servicio.fecha.toIso8601String()),
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF52341A).withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.store,
                  size: 16,
                  color: Color(0xFF52341A),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    servicio.tallerNombre,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                ),
              ],
            ),
            if (servicio.diagnosticoDescripcion != null) ...[
              const SizedBox(height: 8),
              Text(
                servicio.diagnosticoDescripcion!,
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF52341A).withOpacity(0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            // Botón de valoración para servicios completados
            if (esCompletado) ...[
              const SizedBox(height: 12),
              FutureBuilder<Valoracion?>(
                future: _cargarValoracion(servicio.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  
                  final valoracion = snapshot.data;
                  
                  if (valoracion != null) {
                    // Ya está valorado - mostrar estrellas
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < valoracion.puntos ? Icons.star : Icons.star_border,
                              size: 20,
                              color: index < valoracion.puntos ? Colors.amber : Colors.grey,
                            );
                          }),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              valoracion.comentario ?? 'Sin comentario',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF52341A).withOpacity(0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _mostrarDialogValoracion(servicio, valoracion),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            ),
                            child: const Text(
                              'Editar',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // No está valorado - mostrar botón
                    return ElevatedButton.icon(
                      onPressed: () => _mostrarDialogValoracion(servicio, null),
                      icon: const Icon(Icons.star_border, size: 18),
                      label: const Text('Valorar Servicio'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF932D30),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Future<Valoracion?> _cargarValoracion(int servicioId) async {
    try {
      final token = await Session.getToken();
      if (token == null) return null;
      return await ClienteApi.obtenerValoracion(token, servicioId);
    } catch (e) {
      print('Error al cargar valoración: $e');
      return null;
    }
  }
  
  Future<void> _mostrarDialogValoracion(ServicioHistorial servicio, Valoracion? valoracionExistente) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => ValoracionDialog(
        servicioId: servicio.id,
        tallerNombre: servicio.tallerNombre,
        valoracionExistente: valoracionExistente,
      ),
    );
    
    // Si se valoró exitosamente, recargar el historial
    if (resultado == true) {
      _loadHistorial();
    }
  }

  String _formatFecha(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return 'Hace ${difference.inMinutes}m';
        }
        return 'Hace ${difference.inHours}h';
      } else if (difference.inDays < 7) {
        return 'Hace ${difference.inDays}d';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return '';
    }
  }
}
