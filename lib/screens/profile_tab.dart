import 'package:flutter/material.dart';
import '../services/session.dart';
import '../services/profile_api.dart';
import '../services/auth_api.dart';
import 'edit_profile_screen.dart';
import 'manage_user_screen.dart';
import 'change_password_screen.dart';
import 'vehicles_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await Session.getToken();
      if (token != null) {
        final profile = await ProfileApi.getProfile(token);
        setState(() {
          _profile = profile;
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

  @override
  Widget build(BuildContext context) {
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
            Text(
              'Error al cargar el perfil',
              style: const TextStyle(
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
              onPressed: _loadProfile,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: const Color(0xFF932D30),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Foto de perfil y datos básicos
            _buildProfileHeader(),
            const SizedBox(height: 32),
            
            // Información personal
            _buildPersonalInfo(),
            const SizedBox(height: 24),
            
            // Botones de acción
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final profile = _profile!;
    final hasPhoto = profile['url_img_perfil'] != null && profile['url_img_perfil'].toString().isNotEmpty;
    
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Foto de perfil
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF932D30),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: hasPhoto
                    ? Image.network(
                        profile['url_img_perfil'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAvatar();
                        },
                      )
                    : _buildDefaultAvatar(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Nombre y email
            Text(
              _getDisplayName(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              profile['email'] ?? 'Sin email',
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFF52341A).withOpacity(0.8),
              ),
            ),
            if (profile['username'] != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF932D30).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '@${profile['username']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF932D30),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFFE6E8E5),
      child: const Icon(
        Icons.person,
        size: 60,
        color: Color(0xFF932D30),
      ),
    );
  }

  String _getDisplayName() {
    final profile = _profile!;
    final nombre = profile['nombre'];
    final apellidoP = profile['apellido_p'];
    final apellidoM = profile['apellido_m'];
    
    if (nombre != null && nombre.toString().isNotEmpty) {
      String fullName = nombre.toString();
      if (apellidoP != null && apellidoP.toString().isNotEmpty) {
        fullName += ' ${apellidoP}';
      }
      if (apellidoM != null && apellidoM.toString().isNotEmpty) {
        fullName += ' ${apellidoM}';
      }
      return fullName;
    }
    
    if (profile['username'] != null) {
      return profile['username'];
    }
    
    return 'Usuario';
  }

  Widget _buildPersonalInfo() {
    final profile = _profile!;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Personal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow(Icons.badge, 'CI', profile['ci']),
            _buildInfoRow(Icons.phone, 'Teléfono', profile['telefono']),
            _buildInfoRow(Icons.location_on, 'Dirección', profile['direccion']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, dynamic value) {
    final displayValue = value?.toString().isNotEmpty == true ? value.toString() : 'No especificado';
    final isEmpty = value?.toString().isNotEmpty != true;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isEmpty ? const Color(0xFF52341A).withOpacity(0.5) : const Color(0xFF932D30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
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
                  displayValue,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isEmpty ? const Color(0xFF52341A).withOpacity(0.5) : const Color(0xFF2C2C2C),
                    fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final profile = _profile!;
    final hasUser = profile['username'] != null;
    
    return Column(
      children: [
        // Completar datos personales
        _buildActionButton(
          icon: Icons.edit,
          title: 'Completar Datos Personales',
          subtitle: 'Actualiza tu información personal',
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProfileScreen(profile: profile),
              ),
            );
            if (result == true) {
              _loadProfile();
            }
          },
        ),
        const SizedBox(height: 16),
        
        // Gestionar usuario
        _buildActionButton(
          icon: hasUser ? Icons.account_circle : Icons.person_add,
          title: hasUser ? 'Gestionar Usuario' : 'Crear Usuario',
          subtitle: hasUser 
              ? 'Actualizar nombre de usuario y foto' 
              : 'Crea tu usuario y contraseña',
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManageUserScreen(profile: profile),
              ),
            );
            if (result == true) {
              _loadProfile();
            }
          },
        ),
        
        // Cambiar contraseña (solo si tiene usuario)
        if (hasUser) ...[
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.lock_reset,
            title: 'Cambiar Contraseña',
            subtitle: 'Actualiza tu contraseña de acceso',
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangePasswordScreen(email: profile['email']),
                ),
              );
              if (result == true) {
                // Opcional: cerrar sesión después de cambiar contraseña
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Contraseña Actualizada'),
                    content: const Text('Tu contraseña ha sido actualizada. Por seguridad, debes iniciar sesión nuevamente.'),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          final token = await Session.getToken();
                          if (token != null) {
                            await AuthApi.logout(token);
                          }
                          await Session.clearToken();
                          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                        },
                        child: const Text('Aceptar'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
        
        const SizedBox(height: 16),
        
        // Vehículos registrados
        _buildActionButton(
          icon: Icons.directions_car,
          title: 'Mis Vehículos',
          subtitle: 'Gestionar vehículos registrados',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VehiclesScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF932D30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
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
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF52341A).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF932D30),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}