import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/session.dart';
import '../services/service_request_api.dart';
import 'dart:async';

class ServiceRequestScreen extends StatefulWidget {
  final int diagnosticoId;

  const ServiceRequestScreen({Key? key, required this.diagnosticoId}) : super(key: key);

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  List<Map<String, dynamic>> _talleres = [];
  bool _loading = true;
  bool _generando = false;
  bool _enviando = false;
  String? _errorMessage;
  Map<String, dynamic>? _resultadoGeneracion;

  @override
  void initState() {
    super.initState();
    _loadTalleres();
  }

  Future<void> _loadTalleres() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final token = await Session.getToken();
      if (token != null) {
        final talleres = await ServiceRequestApi.listarTalleresSugeridos(token, widget.diagnosticoId);
        setState(() {
          _talleres = talleres;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Error al cargar talleres: $e';
      });
    }
  }

  Future<void> _generarSolicitudesAutomaticas() async {
    setState(() => _generando = true);

    try {
      final token = await Session.getToken();
      if (token != null) {
        final resultado = await ServiceRequestApi.generarSolicitudesAutomaticas(
          token,
          widget.diagnosticoId,
        );

        setState(() {
          _resultadoGeneracion = resultado;
          _generando = false;
        });

        if (!mounted) return;

        // Mostrar resultado
        final solicitudesCreadas = resultado['solicitudes_creadas'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se enviaron $solicitudesCreadas solicitudes a talleres sugeridos'),
            backgroundColor: Colors.green,
          ),
        );

        // Recargar talleres
        await _loadTalleres();
      }
    } catch (e) {
      setState(() => _generando = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _solicitarServicioManual(Map<String, dynamic> tallerInfo) async {
    final taller = tallerInfo['taller'];
    final comentarioController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Solicitar servicio a ${taller['nombre']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Distancia: ${tallerInfo['distancia_km']} km'),
              const SizedBox(height: 8),
              if (tallerInfo['especialidades_disponibles'] != null &&
                  (tallerInfo['especialidades_disponibles'] as List).isNotEmpty) ...[
                const Text(
                  'Especialidades:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...(tallerInfo['especialidades_disponibles'] as List).map(
                  (esp) => Text('• $esp', style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: comentarioController,
                decoration: const InputDecoration(
                  labelText: 'Comentario (opcional)',
                  hintText: 'Ej: Necesito atención urgente',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 500,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar Solicitud'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => _enviando = true);

      try {
        final token = await Session.getToken();
        if (token != null) {
          await ServiceRequestApi.solicitarServicioTaller(
            token,
            widget.diagnosticoId,
            taller['id'],
            comentario: comentarioController.text.trim().isEmpty 
                ? null 
                : comentarioController.text.trim(),
          );

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Solicitud enviada a ${taller['nombre']}'),
              backgroundColor: Colors.green,
            ),
          );

          // Recargar talleres
          await _loadTalleres();
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() => _enviando = false);
      }
    }
  }

  Future<void> _agregarComentario(Map<String, dynamic> tallerInfo) async {
    final taller = tallerInfo['taller'];
    final solicitudId = tallerInfo['solicitud_id'];
    final comentarioController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Agregar comentario para ${taller['nombre']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'El taller podrá ver este comentario junto con tu solicitud.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: comentarioController,
                decoration: const InputDecoration(
                  labelText: 'Comentario',
                  hintText: 'Ej: Necesito atención urgente',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                maxLength: 500,
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (confirmar == true && comentarioController.text.trim().isNotEmpty) {
      setState(() => _enviando = true);

      try {
        final token = await Session.getToken();
        if (token != null) {
          await ServiceRequestApi.actualizarComentario(
            token,
            solicitudId,
            comentarioController.text.trim(),
          );

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comentario guardado'),
              backgroundColor: Colors.green,
            ),
          );

          // Recargar talleres
          await _loadTalleres();
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() => _enviando = false);
      }
    }
  }

  Future<void> _verEnMapa(Map<String, dynamic> tallerInfo) async {
    final taller = tallerInfo['taller'];
    
    setState(() => _loading = true);

    try {
      final token = await Session.getToken();
      if (token != null) {
        final ubicacionData = await ServiceRequestApi.obtenerUbicacionTaller(
          token,
          taller['id'],
        );

        if (!mounted) return;

        final ubicacion = ubicacionData['ubicacion'] as String;
        final parts = ubicacion.split(',');
        final lat = double.parse(parts[0]);
        final lon = double.parse(parts[1]);

        // Mostrar modal con mapa
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Container(
              height: 500,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          taller['nombre'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Distancia: ${tallerInfo['distancia_km']} km',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(lat, lon),
                          initialZoom: 15.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.mobile_repo',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(lat, lon),
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Color(0xFF932D30),
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16),
                      const SizedBox(width: 8),
                      Text(taller['telefono']),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.email, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          taller['email'],
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar ubicación: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF932D30),
        foregroundColor: Colors.white,
        title: const Text('Solicitar Servicio'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _talleres.isEmpty
                  ? _buildEmptyView()
                  : _buildTalleresView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTalleres,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No se encontraron talleres cercanos con las especialidades requeridas',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTalleres,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTalleresView() {
    // Separar talleres sugeridos (con solicitud) de otros
    final talleresSugeridos = _talleres.where((t) => t['tiene_solicitud'] == true).toList();
    final otrosTalleres = _talleres.where((t) => t['tiene_solicitud'] == false).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botón para generar solicitudes automáticas
          if (talleresSugeridos.isEmpty && otrosTalleres.isNotEmpty)
            Card(
              elevation: 4,
              color: const Color(0xFF932D30),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Generar Solicitudes Automáticas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'El sistema enviará solicitudes a los talleres más cercanos con las especialidades necesarias',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _generando ? null : _generarSolicitudesAutomaticas,
                        icon: _generando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF932D30),
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(_generando ? 'Generando...' : 'Generar Solicitudes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF932D30),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (talleresSugeridos.isEmpty && otrosTalleres.isNotEmpty)
            const SizedBox(height: 24),

          // Talleres sugeridos (con solicitud enviada)
          if (talleresSugeridos.isNotEmpty) ...[
            _buildSectionHeader(
              'Talleres Sugeridos',
              '${talleresSugeridos.length} solicitud${talleresSugeridos.length != 1 ? 'es' : ''} enviada${talleresSugeridos.length != 1 ? 's' : ''}',
              Icons.recommend,
              Colors.green,
            ),
            const SizedBox(height: 12),
            ...talleresSugeridos.map((tallerInfo) => _buildTallerCard(tallerInfo, true)),
            const SizedBox(height: 24),
          ],

          // Otros talleres (sin solicitud)
          if (otrosTalleres.isNotEmpty) ...[
            _buildSectionHeader(
              'Otros Talleres Cercanos',
              '${otrosTalleres.length} disponible${otrosTalleres.length != 1 ? 's' : ''}',
              Icons.location_on,
              const Color(0xFF932D30),
            ),
            const SizedBox(height: 12),
            ...otrosTalleres.map((tallerInfo) => _buildTallerCard(tallerInfo, false)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF52341A).withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTallerCard(Map<String, dynamic> tallerInfo, bool tieneSolicitud) {
    final taller = tallerInfo['taller'];
    final distancia = tallerInfo['distancia_km'];
    final especialidades = tallerInfo['especialidades_disponibles'] as List? ?? [];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        taller['nombre'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Color(0xFF932D30)),
                          const SizedBox(width: 4),
                          Text(
                            '$distancia km',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF52341A)),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${taller['puntos']}',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF52341A)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (tieneSolicitud)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Enviado',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Color(0xFF52341A)),
                const SizedBox(width: 4),
                Text(taller['telefono'], style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.email, size: 16, color: Color(0xFF52341A)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    taller['email'],
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (especialidades.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Especialidades disponibles:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: especialidades.map((esp) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF932D30).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      esp.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF932D30),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (!tieneSolicitud) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _enviando ? null : () => _solicitarServicioManual(tallerInfo),
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Enviar Solicitud'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF932D30),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _enviando ? null : () => _agregarComentario(tallerInfo),
                      icon: const Icon(Icons.comment, size: 18),
                      label: const Text('Comentario'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF932D30),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _verEnMapa(tallerInfo),
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('Ver Mapa'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF932D30),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
