import 'package:flutter/material.dart';
import '../services/cliente_api.dart';
import '../services/session.dart';

class ValoracionDialog extends StatefulWidget {
  final int servicioId;
  final String tallerNombre;
  final Valoracion? valoracionExistente;

  const ValoracionDialog({
    Key? key,
    required this.servicioId,
    required this.tallerNombre,
    this.valoracionExistente,
  }) : super(key: key);

  @override
  State<ValoracionDialog> createState() => _ValoracionDialogState();
}

class _ValoracionDialogState extends State<ValoracionDialog> {
  int _puntos = 5;
  final TextEditingController _comentarioController = TextEditingController();
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    if (widget.valoracionExistente != null) {
      _puntos = widget.valoracionExistente!.puntos;
      _comentarioController.text = widget.valoracionExistente!.comentario ?? '';
    }
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _enviarValoracion() async {
    setState(() => _enviando = true);

    try {
      final token = await Session.getToken();
      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      if (widget.valoracionExistente != null) {
        // Actualizar valoración existente
        await ClienteApi.actualizarValoracion(
          token,
          widget.servicioId,
          _puntos,
          _comentarioController.text.trim().isEmpty
              ? null
              : _comentarioController.text.trim(),
        );
      } else {
        // Crear nueva valoración
        await ClienteApi.valorarServicio(
          token,
          widget.servicioId,
          _puntos,
          _comentarioController.text.trim().isEmpty
              ? null
              : _comentarioController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Retornar true para indicar éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.valoracionExistente != null
                  ? '¡Valoración actualizada!'
                  : '¡Gracias por tu valoración!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono y título
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF932D30).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.star,
                    size: 48,
                    color: Color(0xFF932D30),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.valoracionExistente != null
                      ? 'Actualizar Valoración'
                      : 'Valorar Servicio',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.tallerNombre,
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF52341A).withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),

                // Selector de estrellas
                const Text(
                  '¿Cómo calificarías el servicio?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF52341A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final estrella = index + 1;
                    return GestureDetector(
                      onTap: _enviando ? null : () {
                        setState(() => _puntos = estrella);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          estrella <= _puntos ? Icons.star : Icons.star_border,
                          size: 36,
                          color: estrella <= _puntos
                              ? Colors.amber
                              : Colors.grey.shade400,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  _getTextoCalificacion(_puntos),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getColorCalificacion(_puntos),
                  ),
                ),
                const SizedBox(height: 20),

                // Campo de comentario
                TextField(
                  controller: _comentarioController,
                  enabled: !_enviando,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: InputDecoration(
                    labelText: 'Comentario (opcional)',
                    hintText: 'Cuéntanos sobre tu experiencia...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF932D30),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _enviando
                            ? null
                            : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFF932D30)),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF932D30),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _enviando ? null : _enviarValoracion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF932D30),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _enviando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                widget.valoracionExistente != null
                                    ? 'Actualizar'
                                    : 'Enviar',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTextoCalificacion(int puntos) {
    switch (puntos) {
      case 1:
        return 'Muy malo';
      case 2:
        return 'Malo';
      case 3:
        return 'Regular';
      case 4:
        return 'Bueno';
      case 5:
        return 'Excelente';
      default:
        return '';
    }
  }

  Color _getColorCalificacion(int puntos) {
    if (puntos <= 2) return Colors.red;
    if (puntos == 3) return Colors.orange;
    return Colors.green;
  }
}
