import 'package:flutter/material.dart';
import '../services/session.dart';
import '../services/vehicle_api.dart';
import 'add_vehicle_screen.dart';
import 'edit_vehicle_screen.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({Key? key}) : super(key: key);

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  List<Map<String, dynamic>> _vehicles = [];
  bool _loading = true;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalVehicles = 0;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles({int page = 0}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await Session.getToken();
      if (token != null) {
        final response = await VehicleApi.getVehicles(
          token,
          skip: page * _itemsPerPage,
          limit: _itemsPerPage,
        );
        
        setState(() {
          _vehicles = List<Map<String, dynamic>>.from(response['items']);
          _totalVehicles = response['total'];
          _totalPages = (_totalVehicles / _itemsPerPage).ceil();
          _currentPage = page;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deleteVehicle(int vehicleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Vehículo'),
        content: const Text('¿Estás seguro de que quieres eliminar este vehículo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF932D30)),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final token = await Session.getToken();
        if (token != null) {
          await VehicleApi.deleteVehicle(token, vehicleId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Vehículo eliminado correctamente'),
              backgroundColor: const Color(0xFF52341A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
          _loadVehicles(page: _currentPage);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: const Color(0xFF932D30),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF932D30),
        foregroundColor: Colors.white,
        title: const Text('Mis Vehículos'),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddVehicleScreen(),
                ),
              );
              if (result == true) {
                _loadVehicles();
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF932D30)),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFF932D30),
            ),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar vehículos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF52341A).withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loadVehicles(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_vehicles.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Lista de vehículos
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadVehicles(page: _currentPage),
            color: const Color(0xFF932D30),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _vehicles.length,
              itemBuilder: (context, index) {
                return _buildVehicleCard(_vehicles[index]);
              },
            ),
          ),
        ),
        
        // Paginación
        if (_totalPages > 1) _buildPagination(),
      ],
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
              Icons.directions_car_outlined,
              size: 64,
              color: Color(0xFF932D30),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No tienes vehículos registrados',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Registra tu primer vehículo para comenzar',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF52341A).withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddVehicleScreen(),
                ),
              );
              if (result == true) {
                _loadVehicles();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Registrar Vehículo'),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF932D30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle['matricula'] ?? 'Sin matrícula',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      Text(
                        '${vehicle['marca'] ?? 'Sin marca'} ${vehicle['modelo'] ?? 'Sin modelo'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF52341A).withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditVehicleScreen(vehicle: vehicle),
                        ),
                      );
                      if (result == true) {
                        _loadVehicles(page: _currentPage);
                      }
                    } else if (value == 'delete') {
                      _deleteVehicle(vehicle['id']);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Color(0xFF52341A)),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Color(0xFF932D30)),
                          SizedBox(width: 8),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Detalles del vehículo
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem('Año', vehicle['anio']?.toString() ?? 'N/A'),
                ),
                Expanded(
                  child: _buildDetailItem('Color', vehicle['color'] ?? 'N/A'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem('Tipo', _getTipoLabel(vehicle['tipo']) ?? 'N/A'),
                ),
                const Expanded(child: SizedBox()), // Espacio vacío para mantener el layout
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF52341A).withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C2C2C),
          ),
        ),
      ],
    );
  }

  String? _getTipoLabel(String? tipo) {
    const tipoLabels = {
      'auto': 'Automóvil',
      'camioneta': 'Camioneta',
      'moto': 'Motocicleta',
      'camion': 'Camión',
      'microbus': 'Microbús',
      'otro': 'Otro',
    };
    return tipoLabels[tipo];
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Página ${_currentPage + 1} de $_totalPages',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF52341A),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _currentPage > 0 ? () => _loadVehicles(page: _currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left),
                color: const Color(0xFF932D30),
              ),
              IconButton(
                onPressed: _currentPage < _totalPages - 1 ? () => _loadVehicles(page: _currentPage + 1) : null,
                icon: const Icon(Icons.chevron_right),
                color: const Color(0xFF932D30),
              ),
            ],
          ),
        ],
      ),
    );
  }
}