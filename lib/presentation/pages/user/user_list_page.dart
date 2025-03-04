import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:attendance_app/core/platform/platform_info.dart';
import 'package:attendance_app/domain/entities/user.dart';
import 'package:attendance_app/presentation/bloc/user/user_bloc.dart';
import 'package:attendance_app/presentation/pages/user/user_form_page.dart';
import 'package:attendance_app/presentation/widgets/common/app_bar.dart';
import 'package:attendance_app/presentation/widgets/common/loading_indicator.dart';
import 'package:attendance_app/presentation/widgets/common/snackbar.dart';

/// Página para listar usuarios
class UserListPage extends StatefulWidget {
  /// Usuario actual
  final User currentUser;

  /// Información de la plataforma
  final PlatformInfo platformInfo;

  /// Constructor
  const UserListPage({
    Key? key,
    required this.currentUser,
    required this.platformInfo,
  }) : super(key: key);

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final TextEditingController _searchController = TextEditingController();
  UserRole? _selectedRole;
  bool? _selectedStatus;

  @override
  void initState() {
    super.initState();
    // Cargar usuarios
    context.read<UserBloc>().add(LoadUsersEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.currentUser.isAdmin;

    return Scaffold(
      appBar: AttendanceAppBar(
        title: 'Usuarios',
        currentUser: widget.currentUser,
        platformInfo: widget.platformInfo,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar usuarios...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterUsers();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (_) => _filterUsers(),
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.person_add),
                    tooltip: 'Agregar usuario',
                    onPressed: () => _navigateToUserForm(context),
                  ),
                ],
              ],
            ),
          ),

          // Filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Filtro por rol
                Expanded(
                  child: DropdownButtonFormField<UserRole?>(
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    value: _selectedRole,
                    items: const [
                      DropdownMenuItem<UserRole?>(
                        value: null,
                        child: Text('Todos'),
                      ),
                      DropdownMenuItem<UserRole?>(
                        value: UserRole.admin,
                        child: Text('Administrador'),
                      ),
                      DropdownMenuItem<UserRole?>(
                        value: UserRole.supervisor,
                        child: Text('Supervisor'),
                      ),
                      DropdownMenuItem<UserRole?>(
                        value: UserRole.assistant,
                        child: Text('Asistente'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value;
                      });
                      _filterUsers();
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Filtro por estado
                Expanded(
                  child: DropdownButtonFormField<bool?>(
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    value: _selectedStatus,
                    items: const [
                      DropdownMenuItem<bool?>(
                        value: null,
                        child: Text('Todos'),
                      ),
                      DropdownMenuItem<bool?>(
                        value: true,
                        child: Text('Activo'),
                      ),
                      DropdownMenuItem<bool?>(
                        value: false,
                        child: Text('Inactivo'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                      });
                      _filterUsers();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Lista de usuarios
          Expanded(
            child: BlocBuilder<UserBloc, UserState>(
              builder: (context, state) {
                if (state is UserLoading) {
                  return Center(
                    child: AppLoadingIndicator(
                      platformInfo: widget.platformInfo,
                      text: 'Cargando usuarios...',
                    ),
                  );
                } else if (state is UsersLoaded) {
                  final users = state.users;

                  if (users.isEmpty) {
                    return const Center(
                      child: Text('No se encontraron usuarios'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _buildUserCard(user, isAdmin);
                    },
                  );
                } else if (state is UserError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${state.message}',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<UserBloc>().add(LoadUsersEvent());
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Center(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<UserBloc>().add(LoadUsersEvent());
                      },
                      child: const Text('Cargar usuarios'),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(User user, bool isAdmin) {
    String roleName;
    Color roleColor;

    switch (user.role) {
      case UserRole.admin:
        roleName = 'Administrador';
        roleColor = Colors.blue;
        break;
      case UserRole.supervisor:
        roleName = 'Supervisor';
        roleColor = Colors.purple;
        break;
      case UserRole.assistant:
        roleName = 'Asistente';
        roleColor = Colors.green;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: user.isActive ? Colors.green : Colors.grey,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: roleColor,
          backgroundImage: user.profilePicture != null
              ? NetworkImage(user.profilePicture!)
              : null,
          child: user.profilePicture == null
              ? Text(user.name.substring(0, 1).toUpperCase())
              : null,
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    roleName,
                    style: TextStyle(
                      fontSize: 12,
                      color: roleColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: user.isActive
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    user.isActive ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      fontSize: 12,
                      color: user.isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: isAdmin
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    tooltip: 'Editar',
                    onPressed: () => _navigateToUserForm(context, user: user),
                  ),
                  // No permitir eliminar al usuario actual o si no es admin
                  if (user.id != widget.currentUser.id)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Eliminar',
                      onPressed: () => _showDeleteConfirmDialog(context, user),
                    ),
                ],
              )
            : null,
        onTap: isAdmin ? () => _navigateToUserForm(context, user: user) : null,
      ),
    );
  }

  void _filterUsers() {
    // Llama al bloc para filtrar usuarios
    context.read<UserBloc>().add(
          FilterUsersEvent(
            role: _selectedRole,
            isActive: _selectedStatus,
            searchQuery: _searchController.text.isNotEmpty
                ? _searchController.text
                : null,
          ),
        );
  }

  Future<void> _navigateToUserForm(BuildContext context, {User? user}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserFormPage(
          user: user,
          currentUser: widget.currentUser,
          platformInfo: widget.platformInfo,
        ),
      ),
    );

    if (result == true) {
      // Recargar usuarios si se creó o actualizó un usuario
      context.read<UserBloc>().add(LoadUsersEvent());

      AppSnackBar.showSuccess(
        context: context,
        message: user != null
            ? 'Usuario actualizado correctamente'
            : 'Usuario creado correctamente',
        platformInfo: widget.platformInfo,
      );
    }
  }

  Future<void> _showDeleteConfirmDialog(BuildContext context, User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
            '¿Estás seguro de que deseas eliminar al usuario ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Eliminar usuario
      // Aquí deberías implementar la lógica para eliminar el usuario
      AppSnackBar.showSuccess(
        context: context,
        message: 'Usuario eliminado correctamente',
        platformInfo: widget.platformInfo,
      );

      // Recargar la lista de usuarios
      context.read<UserBloc>().add(LoadUsersEvent());
    }
  }
}
