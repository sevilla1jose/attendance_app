import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:attendance_app/core/platform/platform_info.dart';
import 'package:attendance_app/core/utils/validators.dart';
import 'package:attendance_app/domain/entities/user.dart';
import 'package:attendance_app/presentation/bloc/user/user_bloc.dart';
import 'package:attendance_app/presentation/widgets/common/app_bar.dart';
import 'package:attendance_app/presentation/widgets/common/loading_indicator.dart';
import 'package:attendance_app/presentation/widgets/common/snackbar.dart';

/// Página para crear o editar un usuario
class UserFormPage extends StatefulWidget {
  /// Usuario a editar (nulo si es creación)
  final User? user;

  /// Usuario actual (administrador)
  final User currentUser;

  /// Información de la plataforma
  final PlatformInfo platformInfo;

  /// Constructor
  const UserFormPage({
    Key? key,
    this.user,
    required this.currentUser,
    required this.platformInfo,
  }) : super(key: key);

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _identificationController =
      TextEditingController();

  UserRole _selectedRole = UserRole.assistant;
  bool _isActive = true;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();

    // Si es edición, cargamos los datos del usuario
    if (widget.user != null) {
      _nameController.text = widget.user!.name;
      _emailController.text = widget.user!.email;
      _phoneController.text = widget.user!.phone ?? '';
      _identificationController.text = widget.user!.identification ?? '';
      _selectedRole = widget.user!.role;
      _isActive = widget.user!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _identificationController.dispose();
    super.dispose();
  }

  /// Guarda el usuario
  void _saveUser() {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null;
      final identification = _identificationController.text.trim().isNotEmpty
          ? _identificationController.text.trim()
          : null;

      if (widget.user == null) {
        // Crear nuevo usuario
        final password = _passwordController.text.trim();

        context.read<UserBloc>().add(
              AddUserEvent(
                name: name,
                email: email,
                password: password,
                role: _selectedRole,
                phone: phone,
                identification: identification,
              ),
            );
      } else {
        // Actualizar usuario existente
        context.read<UserBloc>().add(
              UpdateUserEvent(
                id: widget.user!.id,
                name: name,
                email: email,
                role: _selectedRole,
                phone: phone,
                identification: identification,
                isActive: _isActive,
              ),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.user != null;
    final String title = isEditing ? 'Editar Usuario' : 'Nuevo Usuario';

    return Scaffold(
      appBar: AppCustomAppBar(
        title: title,
        platformInfo: widget.platformInfo,
      ),
      body: BlocConsumer<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserAdded || state is UserUpdated) {
            // Navegamos atrás y enviamos true para indicar éxito
            Navigator.of(context).pop(true);
          } else if (state is UserError) {
            AppSnackBar.showError(
              context: context,
              message: state.message,
              platformInfo: widget.platformInfo,
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Formulario
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: Validators.validateName,
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                      ),
                      const SizedBox(height: 16),

                      // Contraseña (solo para creación)
                      if (!isEditing) ...[
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          obscureText: !_isPasswordVisible,
                          validator: Validators.validatePassword,
                        ),
                        const SizedBox(height: 16),

                        // Confirmar contraseña
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Confirmar contraseña',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                          ),
                          obscureText: !_isConfirmPasswordVisible,
                          validator: (value) =>
                              Validators.validatePasswordsMatch(
                            _passwordController.text,
                            value,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Teléfono
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono (opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: Validators.validatePhone,
                      ),
                      const SizedBox(height: 16),

                      // Identificación
                      TextFormField(
                        controller: _identificationController,
                        decoration: const InputDecoration(
                          labelText: 'Número de identificación (opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                        validator: (value) => value != null && value.isNotEmpty
                            ? Validators.validateIdentification(value)
                            : null,
                      ),
                      const SizedBox(height: 24),

                      // Rol
                      Text(
                        'Rol del Usuario',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Column(
                          children: [
                            RadioListTile<UserRole>(
                              title: const Text('Administrador'),
                              subtitle:
                                  const Text('Acceso completo al sistema'),
                              value: UserRole.admin,
                              groupValue: _selectedRole,
                              onChanged: (value) {
                                setState(() {
                                  _selectedRole = value!;
                                });
                              },
                            ),
                            RadioListTile<UserRole>(
                              title: const Text('Supervisor'),
                              subtitle: const Text(
                                  'Puede gestionar asistencias y reportes'),
                              value: UserRole.supervisor,
                              groupValue: _selectedRole,
                              onChanged: (value) {
                                setState(() {
                                  _selectedRole = value!;
                                });
                              },
                            ),
                            RadioListTile<UserRole>(
                              title: const Text('Asistente'),
                              subtitle: const Text(
                                  'Solo puede registrar su asistencia'),
                              value: UserRole.assistant,
                              groupValue: _selectedRole,
                              onChanged: (value) {
                                setState(() {
                                  _selectedRole = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Estado (solo para edición)
                      if (isEditing) ...[
                        Row(
                          children: [
                            Text(
                              'Estado',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(width: 16),
                            Switch(
                              value: _isActive,
                              onChanged: (value) {
                                setState(() {
                                  _isActive = value;
                                });
                              },
                            ),
                            Text(_isActive ? 'Activo' : 'Inactivo'),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Botón guardar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: state is UserLoading ? null : _saveUser,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            isEditing ? 'Actualizar' : 'Guardar',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Indicador de carga
              if (state is UserLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: AppLoadingIndicator(
                        platformInfo: widget.platformInfo,
                        color: Colors.white,
                        text: isEditing
                            ? 'Actualizando usuario...'
                            : 'Guardando usuario...',
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
