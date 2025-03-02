import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:attendance_app/core/platform/platform_info.dart';
import 'package:attendance_app/domain/entities/report.dart';
import 'package:attendance_app/domain/entities/user.dart';
import 'package:attendance_app/presentation/bloc/report/report_bloc.dart';
import 'package:attendance_app/presentation/pages/report/report_detail_page.dart';
import 'package:attendance_app/presentation/widgets/common/app_bar.dart';
import 'package:attendance_app/presentation/widgets/common/loading_indicator.dart';
import 'package:attendance_app/presentation/widgets/common/snackbar.dart';
import 'package:attendance_app/data/models/attendance_model.dart';
import 'package:attendance_app/data/models/user_model.dart';
import 'package:attendance_app/data/models/location_model.dart';

/// Página para listar y generar reportes
class ReportListPage extends StatefulWidget {
  /// Usuario actual
  final User currentUser;

  /// Información de la plataforma
  final PlatformInfo platformInfo;

  /// Lista de registros de asistencia
  final List<AttendanceModel> attendanceRecords;

  /// Lista de usuarios
  final List<UserModel> users;

  /// Lista de ubicaciones
  final List<LocationModel> locations;

  /// Constructor
  const ReportListPage({
    Key? key,
    required this.currentUser,
    required this.platformInfo,
    required this.attendanceRecords,
    required this.users,
    required this.locations,
  }) : super(key: key);

  @override
  State<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends State<ReportListPage> {
  ReportType _selectedReportType = ReportType.daily;
  ReportFormat _selectedReportFormat = ReportFormat.pdf;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String? _selectedUserId;
  String? _selectedLocationId;

  @override
  void initState() {
    super.initState();
    _initDates();
  }

  /// Inicializa las fechas según el tipo de reporte
  void _initDates() {
    final now = DateTime.now();

    switch (_selectedReportType) {
      case ReportType.daily:
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case ReportType.weekly:
        // Obtener el primer día de la semana (lunes)
        final dayOfWeek = now.weekday;
        _startDate = DateTime(now.year, now.month, now.day - (dayOfWeek - 1));
        _endDate = DateTime(
            now.year, now.month, now.day + (7 - dayOfWeek), 23, 59, 59);
        break;
      case ReportType.monthly:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(
          now.month < 12 ? now.year : now.year + 1,
          now.month < 12 ? now.month + 1 : 1,
          1,
        ).subtract(const Duration(days: 1));
        _endDate =
            DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
        break;
      case ReportType.custom:
        // Las fechas se mantienen como están
        break;
    }
  }

  /// Genera un reporte
  void _generateReport() {
    final title = _getReportTitle();
    final subtitle = _getReportSubtitle();

    context.read<ReportBloc>().add(
          GenerateReportEvent(
            reportType: _selectedReportType,
            reportFormat: _selectedReportFormat,
            startDate: _startDate,
            endDate: _endDate,
            attendanceRecords: widget.attendanceRecords,
            users: widget.users,
            locations: widget.locations,
            title: title,
            subtitle: subtitle,
            companyName: 'Mi Empresa',
            userId: _selectedUserId,
            locationId: _selectedLocationId,
          ),
        );
  }

  /// Obtiene el título del reporte
  String _getReportTitle() {
    switch (_selectedReportType) {
      case ReportType.daily:
        return 'Reporte de Asistencia Diario';
      case ReportType.weekly:
        return 'Reporte de Asistencia Semanal';
      case ReportType.monthly:
        return 'Reporte de Asistencia Mensual';
      case ReportType.custom:
        return 'Reporte de Asistencia Personalizado';
    }
  }

  /// Obtiene el subtítulo del reporte
  String _getReportSubtitle() {
    final dateFormat = DateFormat('dd/MM/yyyy');

    switch (_selectedReportType) {
      case ReportType.daily:
        return 'Fecha: ${dateFormat.format(_startDate)}';
      case ReportType.weekly:
        return 'Semana: ${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}';
      case ReportType.monthly:
        return 'Mes: ${DateFormat('MMMM yyyy').format(_startDate)}';
      case ReportType.custom:
        return 'Período: ${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}';
    }
  }

  /// Selecciona una fecha
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Si la fecha de inicio es posterior a la de fin, actualizar la de fin
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          // Si la fecha de fin es anterior a la de inicio, actualizar la de inicio
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppCustomAppBar(
        title: 'Reportes',
        platformInfo: widget.platformInfo,
      ),
      body: BlocConsumer<ReportBloc, ReportState>(
        listener: (context, state) {
          if (state is ReportGenerated) {
            AppSnackBar.showSuccess(
              context: context,
              message: 'Reporte generado correctamente',
              platformInfo: widget.platformInfo,
            );

            // Navegar a la vista de detalle del reporte
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportDetailPage(
                  report: Report(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: _getReportTitle(),
                    description: _getReportSubtitle(),
                    type: _selectedReportType,
                    startDate: _startDate,
                    endDate: _endDate,
                    format: _selectedReportFormat,
                    filePath: '',
                    fileSize: state.reportBytes.length,
                    createdAt: DateTime.now(),
                  ),
                  platformInfo: widget.platformInfo,
                ),
              ),
            );
          } else if (state is ReportError) {
            AppSnackBar.showError(
              context: context,
              message: state.message,
              platformInfo: widget.platformInfo,
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título de la página
                const Text(
                  'Generación de Reportes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Tipo de reporte
                const Text(
                  'Tipo de Reporte:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildReportTypeSelector(),
                const SizedBox(height: 24),

                // Formato de reporte
                const Text(
                  'Formato de Reporte:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildReportFormatSelector(),
                const SizedBox(height: 24),

                // Rango de fechas
                const Text(
                  'Rango de Fechas:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDateRangeSelector(),
                const SizedBox(height: 24),

                // Filtros adicionales
                if (_selectedReportType == ReportType.custom) ...[
                  const Text(
                    'Filtros Adicionales:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildAdditionalFilters(),
                  const SizedBox(height: 24),
                ],

                // Botón de generar reporte
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state is ReportLoading ? null : _generateReport,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: state is ReportLoading
                        ? AppLoadingIndicator(
                            platformInfo: widget.platformInfo,
                            color: Colors.white,
                            size: 24,
                          )
                        : const Text(
                            'Generar Reporte',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Lista de reportes generados (en una implementación real, estos se obtendrían de una fuente de datos)
                const Text(
                  'Reportes Recientes:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildRecentReportsList(),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Construye el selector de tipo de reporte
  Widget _buildReportTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            RadioListTile<ReportType>(
              title: const Text('Diario'),
              value: ReportType.daily,
              groupValue: _selectedReportType,
              onChanged: (value) {
                setState(() {
                  _selectedReportType = value!;
                  _initDates();
                });
              },
            ),
            RadioListTile<ReportType>(
              title: const Text('Semanal'),
              value: ReportType.weekly,
              groupValue: _selectedReportType,
              onChanged: (value) {
                setState(() {
                  _selectedReportType = value!;
                  _initDates();
                });
              },
            ),
            RadioListTile<ReportType>(
              title: const Text('Mensual'),
              value: ReportType.monthly,
              groupValue: _selectedReportType,
              onChanged: (value) {
                setState(() {
                  _selectedReportType = value!;
                  _initDates();
                });
              },
            ),
            RadioListTile<ReportType>(
              title: const Text('Personalizado'),
              value: ReportType.custom,
              groupValue: _selectedReportType,
              onChanged: (value) {
                setState(() {
                  _selectedReportType = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el selector de formato de reporte
  Widget _buildReportFormatSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: RadioListTile<ReportFormat>(
                title: const Text('PDF'),
                value: ReportFormat.pdf,
                groupValue: _selectedReportFormat,
                onChanged: (value) {
                  setState(() {
                    _selectedReportFormat = value!;
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<ReportFormat>(
                title: const Text('Excel'),
                value: ReportFormat.excel,
                groupValue: _selectedReportFormat,
                onChanged: (value) {
                  setState(() {
                    _selectedReportFormat = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el selector de rango de fechas
  Widget _buildDateRangeSelector() {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Desde: ${dateFormat.format(_startDate)}'),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _selectedReportType == ReportType.custom
                      ? () => _selectDate(context, true)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Hasta: ${dateFormat.format(_endDate)}'),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _selectedReportType == ReportType.custom
                      ? () => _selectDate(context, false)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construye los filtros adicionales para reportes personalizados
  Widget _buildAdditionalFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Selector de usuario
            DropdownButtonFormField<String?>(
              decoration: const InputDecoration(
                labelText: 'Usuario',
                border: OutlineInputBorder(),
              ),
              value: _selectedUserId,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Todos los usuarios'),
                ),
                ...widget.users.map((user) {
                  return DropdownMenuItem<String?>(
                    value: user.id,
                    child: Text(user.name),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedUserId = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Selector de ubicación
            DropdownButtonFormField<String?>(
              decoration: const InputDecoration(
                labelText: 'Ubicación',
                border: OutlineInputBorder(),
              ),
              value: _selectedLocationId,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Todas las ubicaciones'),
                ),
                ...widget.locations.map((location) {
                  return DropdownMenuItem<String?>(
                    value: location.id,
                    child: Text(location.name),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedLocationId = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la lista de reportes recientes
  Widget _buildRecentReportsList() {
    // En una implementación real, estos datos vendrían de una fuente de datos
    final mockReports = [
      Report(
        id: '1',
        name: 'Reporte Diario',
        description:
            'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.now().subtract(const Duration(days: 1)))}',
        type: ReportType.daily,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().subtract(const Duration(days: 1)),
        format: ReportFormat.pdf,
        filePath: '',
        fileSize: 12345,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Report(
        id: '2',
        name: 'Reporte Semanal',
        description:
            'Semana: ${DateFormat('dd/MM/yyyy').format(DateTime.now().subtract(const Duration(days: 7)))} - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
        type: ReportType.weekly,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
        format: ReportFormat.excel,
        filePath: '',
        fileSize: 54321,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mockReports.length,
      itemBuilder: (context, index) {
        final report = mockReports[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(
                report.format == ReportFormat.pdf
                    ? Icons.picture_as_pdf
                    : Icons.table_chart,
                color: Colors.white,
              ),
            ),
            title: Text(report.name),
            subtitle: Text(report.description),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportDetailPage(
                          report: report,
                          platformInfo: widget.platformInfo,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.green),
                  onPressed: () {
                    AppSnackBar.showInfo(
                      context: context,
                      message: 'Descargando reporte...',
                      platformInfo: widget.platformInfo,
                    );
                  },
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportDetailPage(
                    report: report,
                    platformInfo: widget.platformInfo,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
