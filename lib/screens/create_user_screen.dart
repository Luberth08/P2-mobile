import 'package:flutter/material.dart';
import '../services/session.dart';
import '../services/profile_api.dart';

class CreateUserScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const CreateUserScreen({Key? key, required this.profile}) : super(key: key);

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  
  bool _loading = false;
  bool get _hasUser => widget.profile['username'] != null;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.profile['username'] ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final token = await Session.getToken();
      if (token != null) {
        final data = {
          'username': _usernameController.text.trim(),
        };

        await ProfileApi.updateProfile(token, data);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_hasUser ? 'Usuario actualizado correctamente' : 'Usuario creado correctamente'),
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

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre de usuario es requerido';
    }
    if (value.trim().length < 3) {
      return 'El nombre de usuario debe tener al menos 3 caracteres';
    }
    if (value.trim().length > 20) {
      return 'El nombre de usuario no puede tener más de 20 caracteres';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
      return 'Solo se permiten letras, números y guiones bajos';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF932D30),
        foregroundColor: Colors.white,
        title: Text(_hasUser ? 'Gestionar Usuario' : 'Crear Usuario'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _saveUser,
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
              child: Icon(
                _hasUser ? Icons.account_circle : Icons.person_add,
                size: 64,
                color: const Color(0xFF932D30),
              ),
            ),
            const SizedBox(height: 32),
            
            // Título
            Text(
              _hasUser ? 'Actualizar Usuario' : 'Crear tu Usuario',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _hasUser 
                  ? 'Modifica tu nombre de usuario'
                  : 'Elige un nombre de usuario único para tu cuenta',
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFF52341A).withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            
            // Formulario
            Card(
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de Usuario',
                          prefixIcon: Icon(Icons.alternate_email),
                          hintText: 'mi_usuario_123',
                          helperText: 'Solo letras, números y guiones bajos',
                        ),
                        validator: _validateUsername,
                        enabled: !_loading,
                      ),
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _saveUser,
                          child: _loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  _hasUser ? 'Actualizar Usuario' : 'Crear Usuario',
                                  style: const TextStyle(
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
            ),
            const SizedBox(height: 32),
            
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
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF932D30),
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tu nombre de usuario será visible para otros usuarios y técnicos.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF52341A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!_hasUser) ...[
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Color(0xFF52341A),
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Una vez creado, podrás cambiarlo cuando quieras.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF52341A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}