import 'package:flutter/material.dart';
import '../services/session.dart';
import '../services/diagnostic_api.dart';
import 'service_request_screen.dart';
import 'dart:async';

class DiagnosticResultScreen extends StatefulWidget {
  final int solicitudId;

  const DiagnosticResultScreen({Key? key, required this.solicitudId}) : super(key: key);

  @override
  State<DiagnosticResultScreen> createState() => _DiagnosticResultScreenState();
}

class _DiagnosticResultScreenState extends State<DiagnosticResultScreen> {
  Map<String, dynamic>? _solicitud;
  List<Map<String, dynamic>> _tiposDisponibles = [];
  bool _loading = true;
  bool _deleting = false;
  bool _associating = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Polling cada 3 segundos para verificar si el diagnóstico está listo
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_solicitud?['diagnostico'] != null) {
        timer.cancel();
      } else {
        _loadSolicitud();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadSolicitud(),
      _loadTiposDisponibles(),
    ]);
  }

  Future<void> _loadSolicitud() async {
    try {
      final token = await Session.getToken();
      if (token != null) {
        final solicitud = await DiagnosticApi.getSolicitud(token, widget.solicitudId);
        setState(() {
          _solicitud = solicitud;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _loadTiposDisponibles() async {
    try {
      final token = await Session.getToken();
      if (token != null) {
        final tipos = await DiagnosticApi.getTiposIncidentes(token);
        setState(() {
          _tiposDisponibles = tipos;
        });
        print('✅ Tipos de incidentes cargados: ${tipos.length}');
      }
    } catch (e) {
      print('❌ Error cargando tipos de incidentes: $e');
      // Silencioso, no es crítico
    }
  }

  Future<void> _descartarIncidente(int idDiagnostico, int idTipoIncidente) async {
    if (_deleting) return; // Prevenir múltiples clicks
    
    setState(() => _deleting = true);
    
    try {
      final token = await Session.getToken();
      if (token != null) {
        await DiagnosticApi.descartarIncidente(token, widget.solicitudId, idDiagnostico, idTipoIncidente);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incidente descartado')),
        );
        await _loadSolicitud();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  Future<void> _asociarTipo() async {
    if (_associating) return; // Prevenir múltiples clicks
    
    if (_tiposDisponibles.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay tipos de incidentes disponibles. Contacta al administrador.'),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Tipo de Incidente'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _tiposDisponibles.length,
            itemBuilder: (context, index) {
              final tipo = _tiposDisponibles[index];
              return ListTile(
                title: Text(tipo['concepto']),
                subtitle: Text('Prioridad: ${tipo['prioridad']}'),
                onTap: () => Navigator.pop(context, tipo),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (selected != null) {
      setState(() => _associating = true);
      
      try {
        final token = await Session.getToken();
        if (token != null) {
          await DiagnosticApi.asociarTipoIncidente(
            token,
            widget.solicitudId,
            selected['id'],
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tipo de incidente asociado')),
          );
          await _loadSolicitud();
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        if (mounted) {
          setState(() => _associating = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F2EB),
        appBar: AppBar(
          backgroundColor: const Color(0xFF932D30),
          foregroundColor: Colors.white,
          title: const Text('Diagnóstico'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final diagnostico = _solicitud?['diagnostico'];
    final incidentes = diagnostico?['incidentes'] as List? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF932D30),
        foregroundColor: Colors.white,
        title: const Text('Resultado del Diagnóstico'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado
            _buildEstadoCard(),
            const SizedBox(height: 24),

            // Diagnóstico
            if (diagnostico != null) ...[
              _buildDiagnosticoCard(diagnostico),
              const SizedBox(height: 24),

              // Incidentes detectados
              _buildIncidentesSection(incidentes),
              const SizedBox(height: 24),

              // Botones de acción
              _buildActionButtons(),
            ] else ...[
              _buildWaitingCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoCard() {
    final estado = _solicitud?['estado'] ?? 'desconocido';
    Color estadoColor;
    IconData estadoIcon;

    switch (estado) {
      case 'pendiente':
        estadoColor = Colors.orange;
        estadoIcon = Icons.pending;
        break;
      case 'procesando':
        estadoColor = Colors.blue;
        estadoIcon = Icons.sync;
        break;
      case 'diagnosticada': // Backend usa 'diagnosticada' no 'completada'
        estadoColor = Colors.green;
        estadoIcon = Icons.check_circle;
        break;
      case 'cancelada':
        estadoColor = Colors.red;
        estadoIcon = Icons.cancel;
        break;
      case 'error':
        estadoColor = Colors.red;
        estadoIcon = Icons.error;
        break;
      default:
        estadoColor = Colors.grey;
        estadoIcon = Icons.help;
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(estadoIcon, color: estadoColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estado',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF52341A),
                    ),
                  ),
                  Text(
                    estado.toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: estadoColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticoCard(Map<String, dynamic> diagnostico) {
    final nivelConfianza = (diagnostico['nivel_confianza'] as num).toDouble();
    final porcentaje = (nivelConfianza * 100).toStringAsFixed(0);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Diagnóstico',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 16),
            if (diagnostico['descripcion'] != null)
              Text(
                diagnostico['descripcion'],
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Nivel de confianza: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '$porcentaje%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF932D30),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentesSection(List incidentes) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Incidentes Detectados',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: (_associating || _deleting) ? null : _asociarTipo,
                  icon: _associating 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_circle),
                  color: const Color(0xFF932D30),
                  tooltip: 'Asociar tipo de incidente',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (incidentes.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No se detectaron incidentes'),
                ),
              )
            else
              ...incidentes.map((incidente) {
                final concepto = incidente['concepto'] ?? 'Desconocido';
                final confianza = ((incidente['nivel_confianza'] as num).toDouble() * 100).toStringAsFixed(0);
                final sugeridoPor = incidente['sugerido_por'] ?? 'ia';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: const Color(0xFFE6E8E5),
                  child: ListTile(
                    leading: Icon(
                      sugeridoPor == 'conductor' ? Icons.person : Icons.smart_toy,
                      color: const Color(0xFF932D30),
                    ),
                    title: Text(concepto),
                    subtitle: Text('Confianza: $confianza%'),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF932D30)),
                      onPressed: _deleting ? null : () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Descartar Incidente'),
                            content: Text('¿Descartar "$concepto"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _descartarIncidente(
                                    incidente['id_diagnostico'],
                                    incidente['id_tipo_incidente'],
                                  );
                                },
                                child: const Text('Descartar'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceRequestScreen(
                    diagnosticoId: _solicitud?['diagnostico']?['id'] ?? 0,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.build),
            label: const Text(
              'Solicitar Servicio',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Procesando diagnóstico...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'La IA está analizando la información proporcionada',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF52341A).withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
