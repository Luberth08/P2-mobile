import 'package:flutter/material.dart';
import '../services/session.dart';
import '../services/diagnostic_api.dart';
import 'diagnostic_result_screen.dart';

class SolicitudesTab extends StatefulWidget {
  const SolicitudesTab({Key? key}) : super(key: key);

  @override
  State<SolicitudesTab> createState() => _SolicitudesTabState();
}

class _SolicitudesTabState extends State<SolicitudesTab> {
  List<Map<String, dynamic>> _solicitudes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSolicitudes();
  }

  Future<void> _loadSolicitudes() async {
    setState(() => _loading = true);
    try {
      final token = await Session.getToken();
      if (token != null) {
        final solicitudes = await DiagnosticApi.getMySolicitudes(token);
        setState(() {
          _solicitudes = solicitudes;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'procesando':
        return Colors.blue;
      case 'diagnosticada': // Backend usa 'diagnosticada' no 'completada'
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      case 'error':
        return Colors.red;
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
      case 'diagnosticada': // Backend usa 'diagnosticada' no 'completada'
        return Icons.check_circle;
      case 'cancelada':
        return Icons.cancel;
      case 'error':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F2EB), Color(0xFFE8E3DA)],
        ),
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _solicitudes.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadSolicitudes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _solicitudes.length,
                    itemBuilder: (context, index) {
                      final solicitud = _solicitudes[index];
                      return _buildSolicitudCard(solicitud);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
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
              Icons.inbox,
              size: 64,
              color: Color(0xFF932D30),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No hay solicitudes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tus solicitudes de diagnóstico aparecerán aquí',
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
              // Header con estado
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
              
              // Descripción
              Text(
                descripcion,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2C2C2C),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Vehículo
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
              
              // Diagnóstico info
              if (diagnostico != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF932D30).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Color(0xFF932D30),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Diagnóstico disponible',
                        style: const TextStyle(
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
