import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:attendance_app/core/platform/platform_info.dart';

/// Barra de navegación inferior adaptable a la plataforma
class AppBottomNavigation extends StatelessWidget {
  /// Índice de la página actual
  final int currentIndex;

  /// Callback cuando se selecciona un ítem
  final Function(int) onTap;

  /// Información de la plataforma
  final PlatformInfo platformInfo;

  /// Constructor de la barra de navegación
  const AppBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.platformInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Usar CupertinoTabBar en iOS y BottomNavigationBar en otras plataformas
    if (platformInfo.platform == AppPlatform.iOS) {
      return CupertinoTabBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: _getNavigationItems(),
        activeColor: CupertinoTheme.of(context).primaryColor,
      );
    } else {
      return BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        items: _getNavigationItems(),
        selectedItemColor: Theme.of(context).primaryColor,
      );
    }
  }

  /// Obtiene los ítems de navegación
  List<BottomNavigationBarItem> _getNavigationItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Inicio',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.access_time),
        label: 'Asistencia',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.people),
        label: 'Usuarios',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.location_on),
        label: 'Ubicaciones',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.bar_chart),
        label: 'Reportes',
      ),
    ];
  }
}

/// Widget de navegación para la aplicación
class AppNavigation extends StatelessWidget {
  /// Índice de la página actual
  final int currentIndex;

  /// Páginas a mostrar
  final List<Widget> pages;

  /// Callback cuando se selecciona un ítem
  final Function(int) onIndexChanged;

  /// Información de la plataforma
  final PlatformInfo platformInfo;

  /// Constructor del widget de navegación
  const AppNavigation({
    Key? key,
    required this.currentIndex,
    required this.pages,
    required this.onIndexChanged,
    required this.platformInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: currentIndex,
        onTap: onIndexChanged,
        platformInfo: platformInfo,
      ),
    );
  }
}
