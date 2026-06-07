import 'package:flutter/material.dart';
import '../services/session.dart';
import '../services/cotizacion_api.dart';
import '../services/vehicle_api.dart';
import '../models/cotizacion.dart';
import '../models/vehiculo.dart' as vehiculo_model;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class CrearCotizacionScreen extends StatefulWidget {
  const CrearCotizacionScreen({Key? key}) : super(key: key);

  @override
  State<CrearCotizacionScreen> createState() => _CrearCotizacionScreenState();
}

class _CrearCotizacionScreenState extends State<CrearCotizacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  
  vehiculo_model.Vehiculo? _vehiculoSeleccionado;
  List<vehiculo_model.Vehiculo> _vehiculos = [];
  bool _loadingVehiculos = true;
  
  Map<String, dynamic>? _servicioSeleccionado;
  List<Map<String, dynamic>> _tiposServicio = [];
  bool _loadingServicios = true;
  
  String? _comentario;
  double? _latitud;
  double? _longitud;
  bool _loadingUbicacion = false;
  
  List<XFile> _fotos = [];
  
  List<Map<String, dynamic>> _talleresDisponibles = [];
  Set<int> _talleresSeleccionados = {};
  bool _loadingTalleres = true;
  
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadVehiculos();
    _loadTiposServicio();
    _loadTalleres();
    _getCurrentLocation();
  }

  Future<void> _loadVehiculos() async {
    setState(() => _loadingVehiculos = true);
    try {
      final token = await Session.getToken();
      if (token != null) {
        final response = await VehicleApi.getVehicles(token);
        final vehiculosList = (response['items'] as List)
            .map((v) => vehiculo_model.Vehiculo.fromJson(v))
            .toList();
        setState(() {
          _vehiculos = vehiculosList;
          _loadingVehiculos = false;
        });
      }
    } catch (e) {
      setState(() => _loadingVehiculos = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar vehículos: $e')),
      );
    }
  }

  Future<void> _loadTiposServicio() async {
    setState(() => _loadingServicios = true);
    try {
      final token = await Session.getToken();
      if (token != null) {
        final response = await CotizacionApi.getTiposServicio(token);
        setState(() {
          _tiposServicio = (response as List).cast<Map<String, dynamic>>();
          _loadingServicios = false;
        });
      }
    } catch (e) {
      setState(() => _loadingServicios = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar tipos de servicio: $e')),
      );
    }
  }

  Future<void> _loadTalleres() async {
    setState(() => _loadingTalleres = true);
    try {
      final token = await Session.getToken();
      if (token != null) {
        final response = await CotizacionApi.getTalleres(token);
        setState(() {
          _talleresDisponibles = response;
          _loadingTalleres = false;
        });
      }
    } catch (e) {
      setState(() => _loadingTalleres = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar talleres: $e')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _loadingUbicacion = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _loadingUbicacion = false);
        if (!mounted) return;
        
        final shouldOpenSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('GPS Deshabilitado'),
            content: const Text(
              'Los servicios de ubicación están deshabilitados. '
              '¿Deseas abrir la configuración para habilitarlos?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Abrir Configuración'),
              ),
            ],
          ),
        );
        
        if (shouldOpenSettings == true) {
          await Geolocator.openLocationSettings();
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permisos de ubicación denegados');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _loadingUbicacion = false);
        if (!mounted) return;
        
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permisos Requeridos'),
            content: const Text(
              'Los permisos de ubicación están denegados permanentemente. '
              'Por favor, habilítalos en la configuración de la aplicación.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Geolocator.openAppSettings();
                },
                child: const Text('Abrir Configuración'),
              ),
            ],
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      setState(() {
        _latitud = position.latitude;
        _longitud = position.longitude;
        _loadingUbicacion = false;
      });
    } catch (e) {
      setState(() => _loadingUbicacion = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener ubicación: ${e.toString()}'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: _getCurrentLocation,
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_fotos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 3 fotos permitidas')),
      );
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _fotos.add(pickedFile);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF932D30)),
                title: const Text('Galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF932D30)),
                title: const Text('Cámara'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removePhoto(int index) {
    setState(() {
      _fotos.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_talleresSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar al menos un taller')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final token = await Session.getToken();
      if (token != null) {
        final request = QuoteRequestCreate(
          idVehiculo: _vehiculoSeleccionado!.id,
          idServicio: _servicioSeleccionado!['id'],
          ubicacionLat: _latitud,
          ubicacionLon: _longitud,
          comentario: _comentario,
          idsTalleres: _talleresSeleccionados.toList(),
          fotos: _fotos.isNotEmpty ? _fotos : null,
        );

        await CotizacionApi.crearSolicitudCotizacion(token, request);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cotización creada exitosamente')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear cotización: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Cotización'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Selección de vehículo
            const Text(
              'Selecciona tu vehículo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _loadingVehiculos
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<vehiculo_model.Vehiculo>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Vehículo',
                    ),
                    value: _vehiculoSeleccionado,
                    items: _vehiculos.map((vehiculo) {
                      return DropdownMenuItem(
                        value: vehiculo,
                        child: Text('${vehiculo.marca} ${vehiculo.modelo} - ${vehiculo.placa}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _vehiculoSeleccionado = value);
                    },
                    validator: (value) {
                      if (value == null) return 'Selecciona un vehículo';
                      return null;
                    },
                  ),
            const SizedBox(height: 24),

            // Selección de servicio
            const Text(
              'Selecciona el tipo de servicio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _loadingServicios
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<Map<String, dynamic>>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Tipo de servicio',
                    ),
                    value: _servicioSeleccionado,
                    items: _tiposServicio.map((servicio) {
                      return DropdownMenuItem(
                        value: servicio,
                        child: Text(servicio['nombre']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _servicioSeleccionado = value);
                    },
                    validator: (value) {
                      if (value == null) return 'Selecciona un tipo de servicio';
                      return null;
                    },
                  ),
            const SizedBox(height: 24),

            // Ubicación
            const Text(
              'Ubicación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_loadingUbicacion)
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E8E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Obteniendo ubicación...',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else if (_latitud != null && _longitud != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.green, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ubicación obtenida',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lat: ${_latitud!.toStringAsFixed(6)}, Lon: ${_longitud!.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.refresh),
                      color: Colors.green,
                      tooltip: 'Actualizar ubicación',
                    ),
                  ],
                ),
              )
            else
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E8E5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, size: 32, color: Colors.orange),
                      const SizedBox(height: 8),
                      const Text(
                        'No se pudo obtener la ubicación',
                        style: TextStyle(fontSize: 14, color: Colors.orange),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.my_location, size: 16),
                        label: const Text('Obtener Ubicación'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF932D30),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Comentario
            const Text(
              'Comentario (opcional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Describe el servicio que necesitas...',
              ),
              onChanged: (value) {
                _comentario = value;
              },
            ),
            const SizedBox(height: 24),

            // Fotos
            const Text(
              'Fotos (opcional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${_fotos.length}/3',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_fotos.isEmpty)
              Center(
                child: TextButton.icon(
                  onPressed: _showImageSourceDialog,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Agregar Fotos'),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._fotos.asMap().entries.map((entry) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                              ? Image.network(
                                  entry.value.path,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image),
                                    );
                                  },
                                )
                              : Image.file(
                                  File(entry.value.path),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removePhoto(entry.key),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF932D30),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  if (_fotos.length < 3)
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6E8E5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF932D30),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Color(0xFF932D30),
                          size: 32,
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 24),

            // Selección de talleres
            const Text(
              'Selecciona los talleres',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _loadingTalleres
                ? const Center(child: CircularProgressIndicator())
                : _talleresDisponibles.isEmpty
                    ? const Text('No hay talleres disponibles')
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _talleresDisponibles.length,
                        itemBuilder: (context, index) {
                          final taller = _talleresDisponibles[index];
                          final isSelected = _talleresSeleccionados.contains(taller['id']);
                          return CheckboxListTile(
                            title: Text(taller['nombre'] ?? 'Sin nombre'),
                            subtitle: taller['telefono'] != null 
                                ? Text(taller['telefono']) 
                                : null,
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _talleresSeleccionados.add(taller['id']);
                                } else {
                                  _talleresSeleccionados.remove(taller['id']);
                                }
                              });
                            },
                          );
                        },
                      ),
            const SizedBox(height: 32),

            // Botón enviar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Enviar Cotización', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
