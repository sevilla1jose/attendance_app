import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:attendance_app/core/platform/platform_info.dart';
import 'package:attendance_app/domain/entities/attendance.dart';
import 'package:attendance_app/domain/entities/location.dart';
import 'package:attendance_app/domain/entities/user.dart';
import 'package:attendance_app/presentation/bloc/attendance/attendance_bloc.dart';
import 'package:attendance_app/presentation/widgets/common/loading_indicator.dart';

/// Página de detalle de un registro de asistencia
class AttendanceDetailPage extends StatelessWidget {
  /// ID del registro de asistencia
  final String attendanceId;

  /// Información de la plataforma
  final PlatformInfo platformInfo;

  /// Usuario actual
  final User currentUser;

  /// Constructor
  const AttendanceDetailPage({
    Key? key,
    required this.attendanceId,
    required this.platformInfo,
    required this.currentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Al iniciar, cargar la información de asistencia
    context
        .read<AttendanceBloc>()
        .add(LoadAttendanceDetailEvent(attendanceId: attendanceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Asistencia'),
      ),
      body: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          if (state is AttendanceLoading) {
            return Center(
              child: AppLoadingIndicator(
                platformInfo: platformInfo,
                text: 'Cargando detalles...',
              ),
            );
          } else if (state is AttendanceDetailLoaded) {
            return _buildAttendanceDetail(
                context, state.attendance, state.user, state.location);
          } else if (state is AttendanceError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AttendanceBloc>().add(
                          LoadAttendanceDetailEvent(
                              attendanceId: attendanceId));
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          } else {
            return const Center(
              child: Text('No se pudo cargar la información de asistencia'),
            );
          }
        },
      ),
    );
  }

  /// Construye la vista de detalle de asistencia
  Widget _buildAttendanceDetail(
    BuildContext context,
    Attendance attendance,
    User user,
    Location location,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con tipo de registro y estado
          _buildHeader(context, attendance),
          const SizedBox(height: 24),

          // Información del empleado
          _buildSectionTitle(context, 'Información del Empleado'),
          _buildEmployeeInfo(context, user),
          const SizedBox(height: 24),

          // Información de la ubicación
          _buildSectionTitle(context, 'Ubicación'),
          _buildLocationInfo(context, location, attendance),
          const SizedBox(height: 24),

          // Información del registro
          _buildSectionTitle(context, 'Detalles del Registro'),
          _buildRegistrationDetails(context, attendance),
          const SizedBox(height: 24),

          // Imagen de foto tomada
          _buildSectionTitle(context, 'Fotografía'),
          _buildPhotoSection(context, attendance),
          const SizedBox(height: 24),

          // Firma
          _buildSectionTitle(context, 'Firma'),
          _buildSignatureSection(context, attendance),
          const SizedBox(height: 32),

          // Botones de acción
          _buildActionButtons(context, attendance),
        ],
      ),
    );
  }

  /// Construye el encabezado con el tipo de registro y su estado
  Widget _buildHeader(BuildContext context, Attendance attendance) {
    String title;
    Color color;

    switch (attendance.type) {
      case AttendanceType.checkIn:
        title = 'Registro de Entrada';
        color = Colors.green;
        break;
      case AttendanceType.checkOut:
        title = 'Registro de Salida';
        color = Colors.red;
        break;
      case AttendanceType.lunchOut:
        title = 'Salida a Almuerzo';
        color = Colors.orange;
        break;
      case AttendanceType.lunchIn:
        title = 'Regreso de Almuerzo';
        color = Colors.amber;
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  attendance.isCheckIn
                      ? Icons.login
                      : attendance.isCheckOut
                          ? Icons.logout
                          : attendance.isLunchOut
                              ? Icons.fastfood
                              : Icons.restaurant,
                  color: color,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: attendance.isValid ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    attendance.isValid ? 'Válido' : 'Inválido',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('EEEE dd/MM/yyyy, HH:mm:ss')
                  .format(attendance.createdAt),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if (!attendance.isValid &&
                attendance.validationMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        attendance.validationMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Construye el título de una sección
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la información del empleado
  Widget _buildEmployeeInfo(BuildContext context, User user) {
    String roleText;
    switch (user.role) {
      case UserRole.admin:
        roleText = 'Administrador';
        break;
      case UserRole.supervisor:
        roleText = 'Supervisor';
        break;
      case UserRole.assistant:
        roleText = 'Asistente';
        break;
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: user.profilePicture != null
                  ? NetworkImage(user.profilePicture!)
                  : null,
              child: user.profilePicture == null
                  ? Text(
                      user.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 28),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: user.isAdmin
                          ? Colors.blue[100]
                          : user.isSupervisor
                              ? Colors.purple[100]
                              : Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      roleText,
                      style: TextStyle(
                        fontSize: 12,
                        color: user.isAdmin
                            ? Colors.blue[800]
                            : user.isSupervisor
                                ? Colors.purple[800]
                                : Colors.green[800],
                      ),
                    ),
                  ),
                  if (user.phone != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          user.phone!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
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

  /// Construye la información de la ubicación
  Widget _buildLocationInfo(
    BuildContext context,
    Location location,
    Attendance attendance,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              location.address,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            if (attendance.latitude != null &&
                attendance.longitude != null) ...[
              const Text(
                'Coordenadas del registro:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.my_location, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Lat: ${attendance.latitude!.toStringAsFixed(6)}, Lon: ${attendance.longitude!.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Aquí se podría agregar un mapa pequeño si se desea
            ],
          ],
        ),
      ),
    );
  }

  /// Construye los detalles del registro
  Widget _buildRegistrationDetails(
      BuildContext context, Attendance attendance) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              context,
              'ID del Registro:',
              attendance.id,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              context,
              'Fecha:',
              DateFormat('dd/MM/yyyy').format(attendance.createdAt),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              context,
              'Hora:',
              DateFormat('HH:mm:ss').format(attendance.createdAt),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              context,
              'Estado:',
              attendance.isValid ? 'Válido' : 'Inválido',
              color: attendance.isValid ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              context,
              'Sincronizado:',
              attendance.isSynced ? 'Sí' : 'No',
              color: attendance.isSynced ? Colors.green : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  /// Construye una fila de detalle con etiqueta y valor
  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  /// Construye la sección de foto
  Widget _buildPhotoSection(BuildContext context, Attendance attendance) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: attendance.photoPath.startsWith('http')
                    ? Image.network(
                        attendance.photoPath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Text('Foto no disponible'),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tomada el ${DateFormat('dd/MM/yyyy HH:mm:ss').format(attendance.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la sección de firma
  Widget _buildSignatureSection(BuildContext context, Attendance attendance) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: attendance.signaturePath.startsWith('http')
                    ? Image.network(
                        attendance.signaturePath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Text('Firma no disponible'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye los botones de acción
  Widget _buildActionButtons(BuildContext context, Attendance attendance) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Solo los administradores y supervisores pueden validar o invalidar registros
        if (currentUser.isAdmin || currentUser.isSupervisor) ...[
          ElevatedButton.icon(
            icon: Icon(
              attendance.isValid ? Icons.cancel : Icons.check_circle,
              color: Colors.white,
            ),
            label: Text(
              attendance.isValid ? 'Invalidar' : 'Validar',
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: attendance.isValid ? Colors.red : Colors.green,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onPressed: () {
              context.read<AttendanceBloc>().add(
                    ToggleAttendanceValidityEvent(
                      id: attendance.id,
                      isValid: !attendance.isValid,
                    ),
                  );
            },
          ),
          const SizedBox(width: 16),
        ],

        // Botón para sincronizar si no está sincronizado
        if (!attendance.isSynced) ...[
          ElevatedButton.icon(
            icon: const Icon(Icons.sync, color: Colors.white),
            label: const Text(
              'Sincronizar',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onPressed: () {
              context.read<AttendanceBloc>().add(
                    SyncAttendanceRecordEvent(id: attendance.id),
                  );
            },
          ),
          const SizedBox(width: 16),
        ],

        // Botón para compartir o descargar
        OutlinedButton.icon(
          icon: const Icon(Icons.share),
          label: const Text('Compartir'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onPressed: () {
            // Implementar compartir
          },
        ),
      ],
    );
  }
}

/// Evento para cargar el detalle de un registro de asistencia
class LoadAttendanceDetailEvent extends AttendanceEvent {
  final String attendanceId;

  const LoadAttendanceDetailEvent({
    required this.attendanceId,
  });

  @override
  List<Object> get props => [attendanceId];
}

/// Evento para cambiar la validez de un registro de asistencia
class ToggleAttendanceValidityEvent extends AttendanceEvent {
  final String id;
  final bool isValid;
  final String? validationMessage;

  const ToggleAttendanceValidityEvent({
    required this.id,
    required this.isValid,
    this.validationMessage,
  });

  @override
  List<Object?> get props => [id, isValid, validationMessage];
}

/// Evento para sincronizar un registro de asistencia
class SyncAttendanceRecordEvent extends AttendanceEvent {
  final String id;

  const SyncAttendanceRecordEvent({
    required this.id,
  });

  @override
  List<Object> get props => [id];
}

/// Estado que indica que se ha cargado el detalle de un registro de asistencia
class AttendanceDetailLoaded extends AttendanceState {
  final Attendance attendance;
  final User user;
  final Location location;

  const AttendanceDetailLoaded({
    required this.attendance,
    required this.user,
    required this.location,
  });

  @override
  List<Object> get props => [attendance, user, location];
}
