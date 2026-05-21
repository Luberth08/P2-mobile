import 'package:flutter/material.dart';
import '../services/session.dart';
import '../services/vehicle_api.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({Key? key}) : super(key: key);

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _matriculaController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _anioController = TextEditingController();
  final _colorController = TextEditingController();
  
  String? _selectedTipo;
  bool _loading = false;

  final List<Map<String, String>> _tiposVehiculo = [
    {'value': 'auto', 'label': 'Automóvil'},
    {'value': 'camioneta', 'label': 'Camioneta'},
    {'value': 'moto', 'label': 'Motocicleta'},
    {'value': 'camion', 'label': 'Camión'},
    {'value': 'microbus', 'label': 'Microbús'},
    {'value': 'otro', 'label': 'Otro'},
  ];

  @override
  void dispose() {
    _matriculaController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _anioController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final token = await Session.getToken();
      if (token != null) {
        final data = {
          'matricula': _matriculaController.text.trim(),
          'marca': _marcaController.text.trim(),
          'modelo': _modeloController.text.trim(),
          'anio': int.tryParse(_anioController.text.trim()),
          'color': _colorController.text.trim().isNotEmpty ? _colorController.text.trim() : null,
          'tipo': _selectedTipo,
        };

        await VehicleApi.createVehicle(token, data);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Vehículo registrado correctamente'),
            backgroundColor: const Color(0xFF52341A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
        
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFF932D30),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
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
        title: const Text('Registrar Vehículo'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _saveVehicle,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Guardar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Icono
              Container(
                padding: const EdgeInsets.all(24),
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
                  Icons.directions_car,
                  size: 64,
                  color: Color(0xFF932D30),
                ),
              ),
              const SizedBox(height: 32),
              
              // Título
              const Text(
                'Registrar Nuevo Vehículo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Completa la información de tu vehículo',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF52341A).withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 32),
              
              // Formulario
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información del Vehículo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Matrícula
                      TextFormField(
                        controller: _matriculaController,
                        decoration: const InputDecoration(
                          labelText: 'Matrícula / Placa',
                          prefixIcon: Icon(Icons.confirmation_number),
                          hintText: 'ABC-1234',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La matrícula es requerida';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 16),
                      
                      // Marca
                      TextFormField(
                        controller: _marcaController,
                        decoration: const InputDecoration(
                          labelText: 'Marca',
                          prefixIcon: Icon(Icons.business),
                          hintText: 'Toyota, Ford, etc.',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La marca es requerida';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      
                      // Modelo
                      TextFormField(
                        controller: _modeloController,
                        decoration: const InputDecoration(
                          labelText: 'Modelo',
                          prefixIcon: Icon(Icons.directions_car_outlined),
                          hintText: 'Corolla, Focus, etc.',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El modelo es requerido';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      
                      // Año
                      TextFormField(
                        controller: _anioController,
                        decoration: const InputDecoration(
                          labelText: 'Año',
                          prefixIcon: Icon(Icons.calendar_today),
                          hintText: '2020',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El año es requerido';
                          }
                          final year = int.tryParse(value.trim());
                          if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                            return 'Ingrese un año válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Color (opcional)
                      TextFormField(
                        controller: _colorController,
                        decoration: const InputDecoration(
                          labelText: 'Color (opcional)',
                          prefixIcon: Icon(Icons.palette),
                          hintText: 'Rojo, Azul, etc.',
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      
                      // Tipo de vehículo
                      DropdownButtonFormField<String>(
                        value: _selectedTipo,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Vehículo',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _tiposVehiculo.map((tipo) {
                          return DropdownMenuItem(
                            value: tipo['value'],
                            child: Text(tipo['label']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTipo = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Seleccione el tipo de vehículo';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Información adicional
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFB76369).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFB76369).withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF932D30),
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Esta información será utilizada para brindarte un mejor servicio de diagnóstico.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF52341A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}