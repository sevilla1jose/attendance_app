import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:attendance_app/core/platform/platform_info.dart';
import 'package:attendance_app/domain/entities/attendance.dart';
import 'package:attendance_app/domain/entities/location.dart';
import 'package:attendance_app/domain/entities/user.dart';
import 'package:attendance_app/presentation/bloc/attendance/attendance_bloc.dart';
import 'package:attendance_app/presentation/bloc/location/location_bloc.dart';
import 'package:attendance_app/presentation/pages/attendance/components/attendance_form.dart';
import 'package:attendance_app/presentation/widgets/common/app_bar.dart';
import 'package:attendance_app/presentation/widgets/common/loading_indicator.dart';
import 'package:attendance_app/presentation/widgets/common/snackbar.dart';

/// Página principal de asistencia
class AttendancePage extends StatefulWidget {
  /// Usuario actual
  final User currentUser;

  /// Información de la plataforma
  final PlatformInfo platformInfo;

  /// Constructor de la página de asistencia
  const AttendancePage({
    Key? key,
    required this.currentUser,
    required this.platformInfo,
  }) : super(key: key);

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Cargar las ubicaciones al iniciar
    context.read<LocationBloc>().add(LoadLocationsEvent());

    // Cargar los registros de asistencia del día actual para el usuario
    context.read<AttendanceBloc>().add(LoadUserDailyAttendanceEvent(
          userId: widget.currentUser.id,
          date: _selectedDate,
        ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Selecciona una fecha',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });

      // Recargar los registros de asistencia para la nueva fecha
      context.read<AttendanceBloc>().add(LoadUserDailyAttendanceEvent(
            userId: widget.currentUser.id,
            date: _selectedDate,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AttendanceAppBar(
        title: 'Asistencia',
        currentUser: widget.currentUser,
        platformInfo: widget.platformInfo,
        onSync: () {
          // Implementar sincronización
          AppSnackBar.showInfo(
            context: context,
            message: 'Sincronizando registros de asistencia...',
            platformInfo: widget.platformInfo,
          );

          // Aquí iría la lógica de sincronización
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Fecha: ${DateFormat('EEEE, dd/MM/yyyy').format(_selectedDate)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_today),
                  tooltip: 'Seleccionar fecha',
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Registrar'),
              Tab(text: 'Mi Registro'),
              Tab(text: 'Historial'),
            ],
            labelColor: Theme.of(context).primaryColor,
            indicatorColor: Theme.of(context).primaryColor,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRegisterTab(),
                _buildMyAttendanceTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterTab() {
    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, locationState) {
        if (locationState is LocationLoading) {
          return Center(
            child: AppLoadingIndicator(
              platformInfo: widget.platformInfo,
              text: 'Cargando ubicaciones...',
            ),
          );
        } else if (locationState is LocationsLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona el tipo de registro:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Opciones de registro
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttendanceOption(
                      context,
                      icon: Icons.login,
                      title: 'Entrada',
                      color: Colors.green,
                      onTap: () => _showAttendanceForm(
                        context,
                        AttendanceType.checkIn,
                        locationState.locations,
                      ),
                    ),
                    _buildAttendanceOption(
                      context,
                      icon: Icons.fastfood,
                      title: 'Salida almuerzo',
                      color: Colors.orange,
                      onTap: () => _showAttendanceForm(
                        context,
                        AttendanceType.lunchOut,
                        locationState.locations,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttendanceOption(
                      context,
                      icon: Icons.restaurant,
                      title: 'Regreso almuerzo',
                      color: Colors.amber,
                      onTap: () => _showAttendanceForm(
                        context,
                        AttendanceType.lunchIn,
                        locationState.locations,
                      ),
                    ),
                    _buildAttendanceOption(
                      context,
                      icon: Icons.logout,
                      title: 'Salida',
                      color: Colors.red,
                      onTap: () => _showAttendanceForm(
                        context,
                        AttendanceType.checkOut,
                        locationState.locations,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Text(
                  'Instrucciones:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '1. Selecciona el tipo de registro que deseas realizar.'),
                        SizedBox(height: 8),
                        Text('2. Selecciona la ubicación donde te encuentras.'),
                        SizedBox(height: 8),
                        Text(
                            '3. Toma una foto de tu rostro para verificar tu identidad.'),
                        SizedBox(height: 8),
                        Text('4. Firma para confirmar el registro.'),
                        SizedBox(height: 8),
                        Text(
                            '5. Asegúrate de estar dentro del área permitida de la ubicación.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (locationState is LocationError) {
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
                  'Error: ${locationState.message}',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<LocationBloc>().add(LoadLocationsEvent());
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
                context.read<LocationBloc>().add(LoadLocationsEvent());
              },
              child: const Text('Cargar ubicaciones'),
            ),
          );
        }
      },
    );
  }

  Widget _buildMyAttendanceTab() {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        if (state is AttendanceLoading) {
          return Center(
            child: AppLoadingIndicator(
              platformInfo: widget.platformInfo,
              text: 'Cargando registros...',
            ),
          );
        } else if (state is UserDailyAttendanceLoaded) {
          if (state.records.isEmpty) {
            return const Center(
              child: Text('No hay registros para este día'),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registros del ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Resumen del día
                _buildDailySummary(state.records),
                const SizedBox(height: 16),

                // Lista de registros
                Expanded(
                  child: ListView.builder(
                    itemCount: state.records.length,
                    itemBuilder: (context, index) {
                      final record = state.records[index];
                      return _buildAttendanceRecord(record);
                    },
                  ),
                ),
              ],
            ),
          );
        } else if (state is AttendanceError) {
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
                    context
                        .read<AttendanceBloc>()
                        .add(LoadUserDailyAttendanceEvent(
                          userId: widget.currentUser.id,
                          date: _selectedDate,
                        ));
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
                context.read<AttendanceBloc>().add(LoadUserDailyAttendanceEvent(
                      userId: widget.currentUser.id,
                      date: _selectedDate,
                    ));
              },
              child: const Text('Cargar registros'),
            ),
          );
        }
      },
    );
  }

  Widget _buildHistoryTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history,
            size: 48,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          const Text(
            'Historial de asistencia',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Selecciona una fecha para ver el historial completo de asistencia',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _selectDate(context),
            icon: const Icon(Icons.calendar_today),
            label: const Text('Seleccionar fecha'),
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

  Widget _buildDailySummary(List<Attendance> records) {
    // Verificar registros de cada tipo
    bool hasCheckIn = false;
    bool hasCheckOut = false;
    bool hasLunchOut = false;
    bool hasLunchIn = false;

    DateTime? checkInTime;
    DateTime? checkOutTime;
    DateTime? lunchOutTime;
    DateTime? lunchInTime;

    for (final record in records) {
      switch (record.type) {
        case AttendanceType.checkIn:
          hasCheckIn = true;
          checkInTime = record.createdAt;
          break;
        case AttendanceType.checkOut:
          hasCheckOut = true;
          checkOutTime = record.createdAt;
          break;
        case AttendanceType.lunchOut:
          hasLunchOut = true;
          lunchOutTime = record.createdAt;
          break;
        case AttendanceType.lunchIn:
          hasLunchIn = true;
          lunchInTime = record.createdAt;
          break;
      }
    }

    // Calcular horas trabajadas
    Duration workTime = Duration.zero;
    if (hasCheckIn && hasCheckOut) {
      workTime = checkOutTime!.difference(checkInTime!);

      // Restar tiempo de almuerzo si existe
      if (hasLunchOut && hasLunchIn) {
        workTime -= lunchInTime!.difference(lunchOutTime!);
      }
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen del día',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Entrada',
                    hasCheckIn
                        ? DateFormat('HH:mm').format(checkInTime!)
                        : 'No registrado',
                    hasCheckIn ? Icons.check_circle : Icons.cancel,
                    hasCheckIn ? Colors.green : Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Salida',
                    hasCheckOut
                        ? DateFormat('HH:mm').format(checkOutTime!)
                        : 'No registrado',
                    hasCheckOut ? Icons.check_circle : Icons.cancel,
                    hasCheckOut ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Almuerzo',
                    hasLunchOut && hasLunchIn
                        ? '${DateFormat('HH:mm').format(lunchOutTime!)} - ${DateFormat('HH:mm').format(lunchInTime!)}'
                        : (hasLunchOut
                            ? 'Salida: ${DateFormat('HH:mm').format(lunchOutTime!)}'
                            : 'No registrado'),
                    (hasLunchOut && hasLunchIn)
                        ? Icons.check_circle
                        : (hasLunchOut ? Icons.error : Icons.cancel),
                    (hasLunchOut && hasLunchIn)
                        ? Colors.green
                        : (hasLunchOut ? Colors.orange : Colors.grey),
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Horas trabajadas',
                    workTime.inMinutes > 0
                        ? '${workTime.inHours}h ${workTime.inMinutes % 60}m'
                        : 'No disponible',
                    workTime.inMinutes > 0
                        ? Icons.access_time
                        : Icons.error_outline,
                    workTime.inMinutes > 0 ? Colors.blue : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRecord(Attendance record) {
    IconData icon;
    String title;
    Color color;

    switch (record.type) {
      case AttendanceType.checkIn:
        icon = Icons.login;
        title = 'Entrada';
        color = Colors.green;
        break;
      case AttendanceType.checkOut:
        icon = Icons.logout;
        title = 'Salida';
        color = Colors.red;
        break;
      case AttendanceType.lunchOut:
        icon = Icons.fastfood;
        title = 'Salida almuerzo';
        color = Colors.orange;
        break;
      case AttendanceType.lunchIn:
        icon = Icons.restaurant;
        title = 'Regreso almuerzo';
        color = Colors.amber;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(DateFormat('HH:mm:ss').format(record.createdAt)),
        trailing: record.isValid
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.error, color: Colors.red),
        onTap: () {
          // Navegar a la página de detalle del registro
          // Navigator.of(context).push(...);
        },
      ),
    );
  }

  void _showAttendanceForm(
      BuildContext context, AttendanceType type, List<Location> locations) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getAttendanceTypeTitle(type),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: AttendanceForm(
                  userId: widget.currentUser.id,
                  type: type,
                  locations: locations,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAttendanceTypeTitle(AttendanceType type) {
    switch (type) {
      case AttendanceType.checkIn:
        return 'Registro de Entrada';
      case AttendanceType.checkOut:
        return 'Registro de Salida';
      case AttendanceType.lunchOut:
        return 'Salida a Almuerzo';
      case AttendanceType.lunchIn:
        return 'Regreso de Almuerzo';
    }
  }
}
