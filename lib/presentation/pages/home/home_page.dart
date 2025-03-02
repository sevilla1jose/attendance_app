import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:attendance_app/presentation/bloc/auth/auth_bloc.dart';
import 'package:attendance_app/presentation/pages/auth/login_page.dart';
import 'package:attendance_app/domain/entities/user.dart';

/// Página principal de la aplicación
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // Páginas del menú
  final List<Widget> _pages = [
    const _DashboardTab(),
    const _AttendanceTab(),
    const _UsersTab(),
    const _LocationsTab(),
    const _ReportsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sistema de Asistencia'),
          actions: [
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sincronizar datos',
              onPressed: () {
                // Implementar la sincronización de datos
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sincronización iniciada')),
                );
              },
            ),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthAuthenticated) {
                  return PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'logout') {
                        context.read<AuthBloc>().add(LogoutEvent());
                      } else if (value == 'profile') {
                        // Navegar al perfil
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        PopupMenuItem<String>(
                          value: 'profile',
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(state.user.name),
                            subtitle: Text(
                              _getRoleText(state.user.role),
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
                            backgroundImage: state.user.profilePicture != null
                                ? NetworkImage(state.user.profilePicture!)
                                : null,
                            child: state.user.profilePicture == null
                                ? Text(state.user.name[0].toUpperCase())
                                : null,
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: _pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          items: const [
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
          ],
        ),
      ),
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
}

/// Pestaña de dashboard
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.dashboard,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          const Text(
            'Panel principal',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bienvenido al Sistema de Asistencia',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            icon: const Icon(Icons.access_time),
            label: const Text('Registrar asistencia'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: () {
              // Navegar a la página de registro de asistencia
            },
          ),
        ],
      ),
    );
  }
}

/// Pestaña de asistencia
class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Registro de Asistencia',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Selecciona el tipo de registro:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),

          // Opciones de registro
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAttendanceOption(
                context,
                icon: Icons.login,
                title: 'Entrada',
                color: Colors.green,
                onTap: () {
                  // Implementar registro de entrada
                },
              ),
              _buildAttendanceOption(
                context,
                icon: Icons.fastfood,
                title: 'Salida almuerzo',
                color: Colors.orange,
                onTap: () {
                  // Implementar salida a almuerzo
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAttendanceOption(
                context,
                icon: Icons.restaurant,
                title: 'Regreso almuerzo',
                color: Colors.amber,
                onTap: () {
                  // Implementar regreso de almuerzo
                },
              ),
              _buildAttendanceOption(
                context,
                icon: Icons.logout,
                title: 'Salida',
                color: Colors.red,
                onTap: () {
                  // Implementar registro de salida
                },
              ),
            ],
          ),

          const SizedBox(height: 48),
          const Text(
            'Últimos registros:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Lista de últimos registros
          Expanded(
            child: ListView.builder(
              itemCount: 5, // Ejemplo con 5 registros
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          index % 2 == 0 ? Colors.green : Colors.red,
                      child: Icon(
                        index % 2 == 0 ? Icons.login : Icons.logout,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      index % 2 == 0 ? 'Entrada' : 'Salida',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Hoy ${index + 8}:${index * 10} AM'),
                    trailing:
                        const Icon(Icons.check_circle, color: Colors.green),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pestaña de usuarios
class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gestión de Usuarios',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Agregar Usuario'),
                onPressed: () {
                  // Implementar agregar usuario
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Barra de búsqueda
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar usuarios...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 16),

          // Filtros
          Row(
            children: [
              DropdownButton<String>(
                hint: const Text('Filtrar por rol'),
                items: const [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text('Todos'),
                  ),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text('Administradores'),
                  ),
                  DropdownMenuItem(
                    value: 'supervisor',
                    child: Text('Supervisores'),
                  ),
                  DropdownMenuItem(
                    value: 'assistant',
                    child: Text('Asistentes'),
                  ),
                ],
                onChanged: (value) {
                  // Implementar filtrado por rol
                },
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                hint: const Text('Estado'),
                items: const [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text('Todos'),
                  ),
                  DropdownMenuItem(
                    value: 'active',
                    child: Text('Activos'),
                  ),
                  DropdownMenuItem(
                    value: 'inactive',
                    child: Text('Inactivos'),
                  ),
                ],
                onChanged: (value) {
                  // Implementar filtrado por estado
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lista de usuarios
          Expanded(
            child: ListView.builder(
              itemCount: 10, // Ejemplo con 10 usuarios
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text('U${index + 1}'),
                    ),
                    title: Text('Usuario ${index + 1}'),
                    subtitle: Text(
                      index % 3 == 0
                          ? 'Administrador'
                          : index % 3 == 1
                              ? 'Supervisor'
                              : 'Asistente',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            // Implementar editar usuario
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            // Implementar eliminar usuario
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Pestaña de ubicaciones
class _LocationsTab extends StatelessWidget {
  const _LocationsTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gestión de Ubicaciones',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_location),
                label: const Text('Agregar Ubicación'),
                onPressed: () {
                  // Implementar agregar ubicación
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Barra de búsqueda
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar ubicaciones...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 16),

          // Mapa de ubicaciones
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('Mapa de Ubicaciones'),
            ),
          ),
          const SizedBox(height: 16),

          // Lista de ubicaciones
          Expanded(
            child: ListView.builder(
              itemCount: 5, // Ejemplo con 5 ubicaciones
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.location_on, color: Colors.white),
                    ),
                    title: Text('Ubicación ${index + 1}'),
                    subtitle: Text('Dirección de la ubicación ${index + 1}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.map, color: Colors.blue),
                          onPressed: () {
                            // Implementar ver en mapa
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () {
                            // Implementar editar ubicación
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Pestaña de reportes
class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Generación de Reportes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Opciones de reporte
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildReportOption(
                context,
                icon: Icons.calendar_today,
                title: 'Reporte Diario',
                description: 'Genera un reporte de asistencia del día actual.',
                onTap: () {
                  // Implementar generación de reporte diario
                },
              ),
              _buildReportOption(
                context,
                icon: Icons.date_range,
                title: 'Reporte Semanal',
                description:
                    'Genera un reporte de asistencia de la semana actual.',
                onTap: () {
                  // Implementar generación de reporte semanal
                },
              ),
              _buildReportOption(
                context,
                icon: Icons.calendar_month,
                title: 'Reporte Mensual',
                description: 'Genera un reporte de asistencia del mes actual.',
                onTap: () {
                  // Implementar generación de reporte mensual
                },
              ),
              _buildReportOption(
                context,
                icon: Icons.settings,
                title: 'Reporte Personalizado',
                description:
                    'Genera un reporte de asistencia con parámetros personalizados.',
                onTap: () {
                  // Implementar generación de reporte personalizado
                },
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Text(
            'Últimos reportes generados:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Lista de reportes generados
          Expanded(
            child: ListView.builder(
              itemCount: 5, // Ejemplo con 5 reportes
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo,
                      child: Icon(
                        index % 2 == 0
                            ? Icons.picture_as_pdf
                            : Icons.table_chart,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                        'Reporte de Asistencia - ${DateTime.now().day - index}/${DateTime.now().month}/${DateTime.now().year}'),
                    subtitle: Text(
                      index % 2 == 0 ? 'PDF (245 KB)' : 'Excel (128 KB)',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.visibility, color: Colors.blue),
                          onPressed: () {
                            // Implementar visualizar reporte
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.download, color: Colors.green),
                          onPressed: () {
                            // Implementar descargar reporte
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
