import 'package:flutter/material.dart';
import '../services/session.dart';
import '../services/auth_api.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';
import 'profile_tab.dart';
import 'create_diagnostic_screen.dart';
import 'servicios_tab.dart';
import 'tecnico_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = false;
  bool _esTecnico = false;
  bool _verificandoRol = true;
  
  List<String> _tabTitles = [];
  List<Widget> _tabs = [];
  List<Widget> _tabViews = [];

  @override
  void initState() {
    super.initState();
    _verificarRolUsuario();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _verificarRolUsuario() async {
    try {
      print('🔍 DEBUG - Iniciando verificación de rol...');
      final token = await Session.getToken();
      print('🔍 DEBUG - Token obtenido: ${token != null ? "Sí" : "No"}');
      
      if (token != null) {
        final esTecnico = await UserService.esTecnico(token);
        print('🔍 DEBUG - Resultado esTecnico: $esTecnico');
        
        setState(() {
          _esTecnico = esTecnico;
          _configurarTabs();
          _verificandoRol = false;
        });
        
        print('🔍 DEBUG - Estado actualizado. _esTecnico: $_esTecnico');
        print('🔍 DEBUG - Número de tabs: ${_tabs.length}');
      } else {
        print('⚠️ DEBUG - No hay token');
        setState(() {
          _configurarTabs();
          _verificandoRol = false;
        });
      }
    } catch (e) {
      print('❌ Error verificando rol: $e');
      setState(() {
        _configurarTabs();
        _verificandoRol = false;
      });
    }
  }

  void _configurarTabs() {
    if (_esTecnico) {
      // Configuración para técnicos
      _tabTitles = [
        'Mi Perfil',
        'Mis Servicios',
        'Diagnóstico',
        'Servicios Cliente'
      ];
      
      _tabs = const [
        Tab(
          icon: Icon(Icons.person),
          text: 'Perfil',
        ),
        Tab(
          icon: Icon(Icons.engineering),
          text: 'Técnico',
        ),
        Tab(
          icon: Icon(Icons.car_repair),
          text: 'Diagnóstico',
        ),
        Tab(
          icon: Icon(Icons.build_circle),
          text: 'Cliente',
        ),
      ];
      
      _tabViews = const [
        ProfileTab(),
        TecnicoTab(),
        CreateDiagnosticScreen(),
        ServiciosTab(),
      ];
    } else {
      // Configuración para clientes normales
      _tabTitles = [
        'Mi Perfil',
        'Solicitar Diagnóstico',
        'Mis Servicios'
      ];
      
      _tabs = const [
        Tab(
          icon: Icon(Icons.person),
          text: 'Mi Perfil',
        ),
        Tab(
          icon: Icon(Icons.car_repair),
          text: 'Diagnóstico',
        ),
        Tab(
          icon: Icon(Icons.build_circle),
          text: 'Servicios',
        ),
      ];
      
      _tabViews = const [
        ProfileTab(),
        CreateDiagnosticScreen(),
        ServiciosTab(),
      ];
    }
    
    _tabController = TabController(length: _tabTitles.length, vsync: this);
  }

  Future<void> _logout() async {
    setState(() => _loading = true);
    try {
      final token = await Session.getToken();
      if (token != null) {
        // Desregistrar token FCM antes del logout
        await NotificationService.unregisterToken();
        await AuthApi.logout(token);
      }
      await Session.clearToken();
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (e) {
      // Incluso si falla el logout en el servidor, limpiamos la sesión local
      await Session.clearToken();
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_verificandoRol) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F2EB),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF932D30)),
              ),
              SizedBox(height: 16),
              Text(
                'Verificando permisos...',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF52341A),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF932D30),
        foregroundColor: Colors.white,
        elevation: 0,
        title: AnimatedBuilder(
          animation: _tabController,
          builder: (context, child) {
            return Row(
              children: [
                Text(
                  _tabTitles[_tabController.index],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_esTecnico) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'TÉCNICO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _logout,
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.logout),
          ),
          // Botón de prueba de notificaciones (temporal)
          IconButton(
            onPressed: () async {
              try {
                await NotificationService.sendTestNotification();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notificación de prueba enviada'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.notifications),
            tooltip: 'Probar notificación',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabViews,
      ),
      bottomNavigationBar: Container(
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
        child: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF932D30),
          unselectedLabelColor: const Color(0xFF52341A).withOpacity(0.6),
          indicatorColor: const Color(0xFF932D30),
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          tabs: _tabs,
        ),
      ),
    );
  }
}