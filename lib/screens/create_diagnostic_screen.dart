import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../services/session.dart';
import '../services/vehicle_api.dart';
import '../services/diagnostic_api.dart';
import 'diagnostic_result_screen.dart';

class CreateDiagnosticScreen extends StatefulWidget {
  const CreateDiagnosticScreen({Key? key}) : super(key: key);

  @override
  State<CreateDiagnosticScreen> createState() => _CreateDiagnosticScreenState();
}

class _CreateDiagnosticScreenState extends State<CreateDiagnosticScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  
  List<Map<String, dynamic>> _vehiculos = [];
  Map<String, dynamic>? _selectedVehiculo;
  List<File> _fotos = [];
  File? _audio;
  String? _audioPath;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _recorderInitialized = false;
  bool _playerInitialized = false;
  int _recordingSeconds = 0;
  int _playingSeconds = 0;
  Position? _ubicacion;
  bool _loading = false;
  bool _loadingVehiculos = true;
  bool _loadingUbicacion = false;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadVehiculos();
    _getCurrentLocation();
    _initRecorder();
    _initPlayer();
  }

  Future<void> _initRecorder() async {
    await _audioRecorder.openRecorder();
    setState(() {
      _recorderInitialized = true;
    });
  }

  Future<void> _initPlayer() async {
    await _audioPlayer.openPlayer();
    setState(() {
      _playerInitialized = true;
    });
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _mapController.dispose();
    _audioRecorder.closeRecorder();
    _audioPlayer.closePlayer();
    super.dispose();
  }

  Future<void> _loadVehiculos() async {
    setState(() => _loadingVehiculos = true);
    try {
      final token = await Session.getToken();
      if (token != null) {
        final response = await VehicleApi.getVehicles(token, limit: 100);
        setState(() {
          _vehiculos = List<Map<String, dynamic>>.from(response['items']);
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

  Future<void> _getCurrentLocation() async {
    setState(() => _loadingUbicacion = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _loadingUbicacion = false);
        if (!mounted) return;
        
        // Mostrar diálogo para habilitar GPS
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
        
        // Mostrar diálogo para ir a configuración de permisos
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
        _ubicacion = position;
        _loadingUbicacion = false;
      });
      
      // Mover la cámara del mapa a la nueva ubicación
      try {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          15.0,
        );
      } catch (e) {
        // Ignorar error si el mapa no está listo
      }
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
          _fotos.add(File(pickedFile.path));
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

  Future<void> _startRecording() async {
    try {
      // Verificar permisos
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permisos de micrófono denegados')),
        );
        return;
      }

      if (!_recorderInitialized) {
        await _initRecorder();
      }
      
      // Obtener directorio temporal
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      // Iniciar grabación
      await _audioRecorder.startRecorder(
        toFile: path,
        codec: Codec.aacMP4,  // Cambiar a aacMP4 para formato .m4a
      );
      
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
        _audioPath = path;
      });
      
      // Contador de segundos
      _startRecordingTimer();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar grabación: $e')),
      );
    }
  }

  void _startRecordingTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording && mounted) {
        setState(() {
          _recordingSeconds++;
        });
        _startRecordingTimer();
      }
    });
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stopRecorder();
      
      if (path != null) {
        setState(() {
          _isRecording = false;
          _audio = File(path);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audio grabado: $_recordingSeconds segundos'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al detener grabación: $e')),
      );
    }
  }

  void _deleteAudio() {
    setState(() {
      _audio = null;
      _audioPath = null;
      _recordingSeconds = 0;
      _playingSeconds = 0;
      _isPlaying = false;
    });
  }

  Future<void> _playAudio() async {
    if (_audio == null || !_playerInitialized) return;

    try {
      setState(() {
        _isPlaying = true;
        _playingSeconds = 0;
      });

      await _audioPlayer.startPlayer(
        fromURI: _audio!.path,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
            _playingSeconds = 0;
          });
        },
      );

      // Contador de reproducción
      _startPlayingTimer();
    } catch (e) {
      setState(() {
        _isPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al reproducir audio: $e')),
      );
    }
  }

  void _startPlayingTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isPlaying && mounted && _playingSeconds < _recordingSeconds) {
        setState(() {
          _playingSeconds++;
        });
        _startPlayingTimer();
      }
    });
  }

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stopPlayer();
      setState(() {
        _isPlaying = false;
        _playingSeconds = 0;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al detener audio: $e')),
      );
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _submitDiagnostic() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedVehiculo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un vehículo')),
      );
      return;
    }

    if (_ubicacion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esperando ubicación...')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final token = await Session.getToken();
      if (token == null) return;

      final ubicacionStr = '${_ubicacion!.latitude},${_ubicacion!.longitude}';
      
      final result = await DiagnosticApi.createDiagnostic(
        token: token,
        descripcion: _descripcionController.text.trim(),
        ubicacion: ubicacionStr,
        matricula: _selectedVehiculo!['matricula'],
        marca: _selectedVehiculo!['marca'],
        modelo: _selectedVehiculo!['modelo'],
        anio: _selectedVehiculo!['anio'],
        color: _selectedVehiculo!['color'],
        tipoVehiculo: _selectedVehiculo!['tipo'],
        fotos: _fotos.isNotEmpty ? _fotos : null,
        audio: _audio,
      );

      if (!mounted) return;

      // Navegar a la pantalla de resultados
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DiagnosticResultScreen(solicitudId: result['id']),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
        title: const Text('Solicitar Diagnóstico'),
      ),
      body: _loadingVehiculos
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seleccionar vehículo
                    _buildVehiculoSelector(),
                    const SizedBox(height: 24),
                    
                    // Ubicación
                    _buildUbicacionCard(),
                    const SizedBox(height: 24),
                    
                    // Descripción
                    _buildDescripcionField(),
                    const SizedBox(height: 24),
                    
                    // Fotos
                    _buildFotosSection(),
                    const SizedBox(height: 24),
                    
                    // Audio (placeholder)
                    _buildAudioSection(),
                    const SizedBox(height: 32),
                    
                    // Botón generar diagnóstico
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submitDiagnostic,
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Generar Diagnóstico',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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

  Widget _buildVehiculoSelector() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vehículo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedVehiculo,
              decoration: const InputDecoration(
                labelText: 'Selecciona tu vehículo',
                prefixIcon: Icon(Icons.directions_car),
              ),
              isExpanded: true,
              menuMaxHeight: 300,
              items: _vehiculos.map((vehiculo) {
                return DropdownMenuItem(
                  value: vehiculo,
                  child: Text(
                    '${vehiculo['matricula']} - ${vehiculo['marca']} ${vehiculo['modelo']}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVehiculo = value;
                });
              },
              validator: (value) {
                if (value == null) return 'Selecciona un vehículo';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUbicacionCard() {
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
                    'Ubicación',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                ),
                if (!_loadingUbicacion)
                  IconButton(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.refresh),
                    color: const Color(0xFF932D30),
                    tooltip: 'Actualizar ubicación',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Mapa o estado de carga
            if (_loadingUbicacion)
              Container(
                height: 200,
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
                        style: TextStyle(fontSize: 14, color: Color(0xFF52341A)),
                      ),
                    ],
                  ),
                ),
              )
            else if (_ubicacion != null)
              Column(
                children: [
                  // Mapa con OpenStreetMap
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 200,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: LatLng(_ubicacion!.latitude, _ubicacion!.longitude),
                          initialZoom: 15.0,
                          minZoom: 5.0,
                          maxZoom: 18.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.mobile_repo',
                            maxZoom: 19,
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(_ubicacion!.latitude, _ubicacion!.longitude),
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
                  const SizedBox(height: 12),
                  
                  // Coordenadas y badge
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Color(0xFF932D30)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lat: ${_ubicacion!.latitude.toStringAsFixed(6)}, Lon: ${_ubicacion!.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF52341A)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Ubicación obtenida',
                          style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E8E5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, size: 48, color: Colors.orange),
                      const SizedBox(height: 16),
                      const Text(
                        'No se pudo obtener la ubicación',
                        style: TextStyle(fontSize: 14, color: Colors.orange, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.my_location, size: 18),
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
          ],
        ),
      ),
    );
  }

  Widget _buildDescripcionField() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Descripción del Problema',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                hintText: 'Describe qué está pasando con tu vehículo...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().length < 5) {
                  return 'Describe el problema (mínimo 5 caracteres)';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFotosSection() {
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
                    'Fotos del Incidente',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                ),
                Text(
                  '${_fotos.length}/3',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF52341A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                          child: Image.file(
                            entry.value,
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
          ],
        ),
      ),
    );
  }

  Widget _buildAudioSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Audio (Opcional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 16),
            
            if (_isRecording)
              // Grabando
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Grabando...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatDuration(_recordingSeconds),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _stopRecording,
                      icon: const Icon(Icons.stop),
                      label: const Text('Detener Grabación'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              )
            else if (_audio != null)
              // Audio grabado
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Audio grabado',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                'Duración: ${_formatDuration(_recordingSeconds)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF52341A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _deleteAudio,
                          icon: const Icon(Icons.delete),
                          color: Colors.red,
                          tooltip: 'Eliminar audio',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Reproductor de audio
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          // Barra de progreso
                          Row(
                            children: [
                              Text(
                                _formatDuration(_playingSeconds),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF52341A),
                                ),
                              ),
                              Expanded(
                                child: Slider(
                                  value: _playingSeconds.toDouble(),
                                  max: _recordingSeconds.toDouble(),
                                  onChanged: null, // No permitir seek por ahora
                                  activeColor: const Color(0xFF932D30),
                                  inactiveColor: const Color(0xFFE6E8E5),
                                ),
                              ),
                              Text(
                                _formatDuration(_recordingSeconds),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF52341A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // Controles de reproducción
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: _isPlaying ? _stopAudio : _playAudio,
                                icon: Icon(
                                  _isPlaying ? Icons.stop : Icons.play_arrow,
                                  size: 32,
                                ),
                                color: const Color(0xFF932D30),
                                tooltip: _isPlaying ? 'Detener' : 'Reproducir',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    ElevatedButton.icon(
                      onPressed: _isPlaying ? null : _startRecording,
                      icon: const Icon(Icons.mic),
                      label: const Text('Grabar Nuevo Audio'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF932D30),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              )
            else
              // Sin audio
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.mic_none,
                      size: 48,
                      color: const Color(0xFF52341A).withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Describe el problema con tu voz',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF52341A).withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _startRecording,
                      icon: const Icon(Icons.mic),
                      label: const Text('Grabar Audio'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF932D30),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
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
}
