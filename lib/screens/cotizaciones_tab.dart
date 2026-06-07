import 'package:flutter/material.dart';
import '../services/session.dart';
import '../services/cotizacion_api.dart';
import '../models/cotizacion.dart';
import 'crear_cotizacion_screen.dart';
import 'cotizacion_detalle_screen.dart';

class CotizacionesTab extends StatefulWidget {
  const CotizacionesTab({Key? key}) : super(key: key);

  @override
  State<CotizacionesTab> createState() => _CotizacionesTabState();
}

class _CotizacionesTabState extends State<CotizacionesTab> {
  List<QuoteRequest> _cotizaciones = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCotizaciones();
  }

  Future<void> _loadCotizaciones() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await Session.getToken();
      if (token != null) {
        final cotizaciones = await CotizacionApi.obtenerMisCotizaciones(token);
        setState(() {
          _cotizaciones = cotizaciones;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'No hay sesión activa';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar cotizaciones: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Cotizaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCotizaciones,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCotizaciones,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _cotizaciones.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No tienes cotizaciones',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CrearCotizacionScreen(),
                                ),
                              );
                              _loadCotizaciones();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Crear Cotización'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCotizaciones,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _cotizaciones.length,
                        itemBuilder: (context, index) {
                          final cotizacion = _cotizaciones[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Color(
                                  int.parse(
                                    cotizacion.estadoColor.replaceAll('#', '0xFF'),
                                  ),
                                ),
                                child: Icon(
                                  _getStatusIcon(cotizacion.estado),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                cotizacion.servicio?.nombre ?? 'Servicio',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cotizacion.vehiculo?.placa ?? 'Vehículo'),
                                  const SizedBox(height: 4),
                                  Text(
                                    cotizacion.estadoTexto,
                                    style: TextStyle(
                                      color: Color(
                                        int.parse(
                                          cotizacion.estadoColor.replaceAll('#', '0xFF'),
                                        ),
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (cotizacion.tieneRespuestas)
                                    Text(
                                      '${cotizacion.respuestasRespondidas.length} respuesta(s)',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CotizacionDetalleScreen(
                                      cotizacionId: cotizacion.id,
                                    ),
                                  ),
                                );
                                _loadCotizaciones();
                              },
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CrearCotizacionScreen(),
            ),
          );
          _loadCotizaciones();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getStatusIcon(String estado) {
    switch (estado) {
      case 'pendiente':
        return Icons.pending;
      case 'con_respuesta':
        return Icons.reply;
      case 'aceptada':
        return Icons.check_circle;
      case 'rechazada':
        return Icons.cancel;
      case 'expirada':
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }
}
