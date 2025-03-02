part of 'report_bloc.dart';

/// Clase base para todos los eventos de reportes
abstract class ReportEvent extends Equatable {
  const ReportEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para generar un reporte
class GenerateReportEvent extends ReportEvent {
  final ReportType reportType;
  final ReportFormat reportFormat;
  final DateTime startDate;
  final DateTime endDate;
  final List<AttendanceModel> attendanceRecords;
  final List<UserModel> users;
  final List<LocationModel> locations;
  final String? title;
  final String? subtitle;
  final String? companyName;
  final String? companyLogo;
  final String? userId;
  final String? locationId;

  const GenerateReportEvent({
    required this.reportType,
    required this.reportFormat,
    required this.startDate,
    required this.endDate,
    required this.attendanceRecords,
    required this.users,
    required this.locations,
    this.title,
    this.subtitle,
    this.companyName,
    this.companyLogo,
    this.userId,
    this.locationId,
  });

  @override
  List<Object?> get props => [
        reportType,
        reportFormat,
        startDate,
        endDate,
        attendanceRecords,
        users,
        locations,
        title,
        subtitle,
        companyName,
        companyLogo,
        userId,
        locationId,
      ];
}

/// Evento para visualizar un reporte
class ViewReportEvent extends ReportEvent {
  final Uint8List reportBytes;
  final String fileName;
  final ReportFormat reportFormat;

  const ViewReportEvent({
    required this.reportBytes,
    required this.fileName,
    required this.reportFormat,
  });

  @override
  List<Object> get props => [
        reportBytes,
        fileName,
        reportFormat,
      ];
}

/// Evento para descargar un reporte
class DownloadReportEvent extends ReportEvent {
  final Uint8List reportBytes;
  final String fileName;

  const DownloadReportEvent({
    required this.reportBytes,
    required this.fileName,
  });

  @override
  List<Object> get props => [
        reportBytes,
        fileName,
      ];
}
