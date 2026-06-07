import 'package:flutter/material.dart';
import '../services/session.dart';
import '../services/cotizacion_api.dart';
import '../models/cotizacion.dart';

class CotizacionDetalleScreen extends StatefulWidget {
  final int cotizacionId;

  const CotizacionDetalleScreen({
    Key? key,
    required this.cotizacionId,
  }) : super(key: key);

  @override
  State<CotizacionDetalleScreen> createState() => _CotizacionDetalleScreenState();
}

class _CotizacionDetalleScreenState extends State<CotizacionDetalleScreen> {
  QuoteRequest? _cotizacion;
  bool _loading = true;
  String? _error;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _loadCotizacion();
  }

  Future<void> _loadCotizacion() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await Session.getToken();
      if (token != null) {
        final cotizacion = await CotizacionApi.obtenerDetalleCotizacion(
          token,
          widget.cotizacionId,
        );
        setState(() {
          _cotizacion = cotizacion;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar cotización: $e';
        _loading = false;
      });
    }
  }

  Future<void> _aceptarCotizacion(QuoteResponse response) async {
    if (_cotizacion?.estado == 'aceptada') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta cotización ya fue aceptada')),
      );
      return;
    }

    setState(() => _accepting = true);

    try {
      final token = await Session.getToken();
      if (token != null) {
        final request = QuoteAcceptRequest(
          idQuoteResponse: response.id,
        );

        await CotizacionApi.aceptarCotizacion(
          token,
          widget.cotizacionId,
          request,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cotización aceptada exitosamente')),
          );
          _loadCotizacion();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al aceptar cotización: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _accepting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Cotización'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCotizacion,
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
                        onPressed: _loadCotizacion,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _cotizacion == null
                  ? const Center(child: Text('Cotización no encontrada'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Información general
                          _buildInfoCard(
                            'Información de la Solicitud',
                            [
                              _buildInfoRow('Servicio', _cotizacion!.servicio?.nombre ?? 'N/A'),
                              _buildInfoRow('Vehículo', 
                                  '${_cotizacion!.vehiculo?.marca} ${_cotizacion!.vehiculo?.modelo} - ${_cotizacion!.vehiculo?.placa}'),
                              _buildInfoRow('Estado', _cotizacion!.estadoTexto,
                                  color: Color(int.parse(_cotizacion!.estadoColor.replaceAll('#', '0xFF')))),
                              _buildInfoRow('Fecha de creación', 
                                  _formatDate(_cotizacion!.fechaCreacion)),
                              if (_cotizacion!.fechaExpiracion != null)
                                _buildInfoRow('Expira', 
                                    _formatDate(_cotizacion!.fechaExpiracion!)),
                              if (_cotizacion!.comentario != null && _cotizacion!.comentario!.isNotEmpty)
                                _buildInfoRow('Comentario', _cotizacion!.comentario!),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Respuestas de cotización
                          const Text(
                            'Cotizaciones Recibidas',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          _cotizacion!.responses.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Text(
                                      'Aún no hay respuestas',
                                      style: TextStyle(fontSize: 16, color: Colors.grey),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _cotizacion!.responses.length,
                                  itemBuilder: (context, index) {
                                    final response = _cotizacion!.responses[index];
                                    return _buildResponseCard(response);
                                  },
                                ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseCard(QuoteResponse response) {
    final puedeAceptar = response.estado == 'respondida' && 
                         _cotizacion?.estado == 'con_respuesta';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Respuesta #${response.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(int.parse(response.estadoColor.replaceAll('#', '0xFF'))),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    response.estadoTexto,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Items de la cotización
            const Text(
              'Desglose de costos:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...response.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.titulo),
                  Text(
                    'Bs ${item.precio.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
            const Divider(),
            
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (response.total != null)
                  Text(
                    'Bs ${response.total!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
            
            if (puedeAceptar) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _accepting ? null : () => _aceptarCotizacion(response),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _accepting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Aceptar Cotización',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
