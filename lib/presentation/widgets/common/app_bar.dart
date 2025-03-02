import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:attendance_app/core/platform/platform_info.dart';
import 'package:attendance_app/domain/entities/user.dart';

/// AppBar personalizado que se adapta a la plataforma
class AppCustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Título del AppBar
  final String title;

  /// Acciones adicionales
  final List<Widget>? actions;

  /// Icono o widget del botón de retroceso
  final Widget? leading;

  /// Información de la plataforma
  final PlatformInfo platformInfo;

  /// Color de fondo
  final Color? backgroundColor;

  /// Si debe mostrar el botón de retroceso automáticamente
  final bool automaticallyImplyLeading;

  /// Si el título debe centrarse
  final bool centerTitle;

  /// Altura del AppBar
  final double height;

  /// Elevación del AppBar
  final double? elevation;

  /// Constructor del AppBar personalizado
  const AppCustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    required this.platformInfo,
    this.backgroundColor,
    this.automaticallyImplyLeading = true,
    this.centerTitle = true,
    this.height = kToolbarHeight,
    this.elevation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (platformInfo.platform == AppPlatform.iOS) {
      return _buildCupertinoAppBar();
    } else {
      return _buildMaterialAppBar(context);
    }
  }

  /// Construye un AppBar con estilo Material
  Widget _buildMaterialAppBar(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      elevation: elevation,
    );
  }

  /// Construye un AppBar con estilo Cupertino
  Widget _buildCupertinoAppBar() {
    return CupertinoNavigationBar(
      middle: Text(title),
      trailing: actions != null && actions!.isNotEmpty
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!,
            )
          : null,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
      border: const Border(
        bottom: BorderSide(
          color: CupertinoColors.lightBackgroundGray,
          width: 0.5,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}

/// AppBar personalizado para la aplicación de asistencia
class AttendanceAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Título del AppBar
  final String title;

  /// Usuario actual
  final User? currentUser;

  /// Función para cerrar sesión
  final VoidCallback? onLogout;

  /// Función para ir al perfil
  final VoidCallback? onProfile;

  /// Función para sincronizar datos
  final VoidCallback? onSync;

  /// Información de la plataforma
  final PlatformInfo platformInfo;

  /// Constructor del AppBar de la aplicación
  const AttendanceAppBar({
    Key? key,
    required this.title,
    this.currentUser,
    this.onLogout,
    this.onProfile,
    this.onSync,
    required this.platformInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Widget> actions = [];

    // Botón de sincronización
    if (onSync != null) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.sync),
          tooltip: 'Sincronizar datos',
          onPressed: onSync,
        ),
      );
    }

    // Menú de usuario
    if (currentUser != null) {
      actions.add(
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'logout' && onLogout != null) {
              onLogout!();
            } else if (value == 'profile' && onProfile != null) {
              onProfile!();
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem<String>(
                value: 'profile',
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(currentUser!.name),
                  subtitle: Text(
                    _getRoleText(currentUser!.role),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Configuración'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Cerrar sesión'),
                ),
              ),
            ];
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: currentUser!.profilePicture != null
                      ? NetworkImage(currentUser!.profilePicture!)
                      : null,
                  child: currentUser!.profilePicture == null
                      ? Text(currentUser!.name[0].toUpperCase())
                      : null,
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      );
    }

    return AppCustomAppBar(
      title: title,
      actions: actions,
      platformInfo: platformInfo,
      backgroundColor: Theme.of(context).primaryColor,
    );
  }

  // Convierte el rol a texto legible
  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.assistant:
        return 'Asistente';
      default:
        return 'Usuario';
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
